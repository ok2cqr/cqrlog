"""Tests for lfm_layout.py. Run: python3 -m unittest tools/test_lfm_layout.py"""
import re, unittest
import lfm_layout as L


def form(body, cw=400, ch=300):
    return (f"object Form1: TForm\n  Left = 0\n  Height = {ch}\n  Top = 0\n  Width = {cw}\n"
            f"  ClientHeight = {ch}\n  ClientWidth = {cw}\n{body}end\n")


def ctl(name, cls, left, top, width, height, *extra):
    lines = [f"  object {name}: {cls}"]
    lines += [f"    {e}" for e in extra if e.startswith("AnchorSide")]
    lines += [f"    Left = {left}", f"    Height = {height}", f"    Top = {top}", f"    Width = {width}"]
    lines += [f"    {e}" for e in extra if not e.startswith("AnchorSide")]
    return "\n".join(lines) + "\n  end\n"


def block(text, name):
    m = re.search(rf"^(\s*)object {name}: \w+\n(.*?)\n\1end$", text, re.S | re.M)
    return m.group(2)


CHAIN = (ctl("chkA", "TCheckBox", 6, 6, 100, 18, "AnchorSideLeft.Control = Form1", "AnchorSideTop.Control = Form1",
             "BorderSpacing.Left = 6", "BorderSpacing.Top = 6", "Caption = 'A'")
         + ctl("chkB", "TCheckBox", 6, 24, 100, 18, "AnchorSideLeft.Control = chkA", "AnchorSideTop.Control = chkA",
               "AnchorSideTop.Side = asrBottom", "Caption = 'B'")
         + ctl("chkC", "TCheckBox", 6, 44, 100, 18, "Caption = 'C'"))


class ParseTest(unittest.TestCase):
    def test_parse_props_and_parent(self):
        f = L.Form.parse(form(CHAIN))
        self.assertEqual(f.find("chkC").props["Top"], "44")
        self.assertEqual(f.find("chkC").parent.name, "Form1")
        self.assertEqual(f.text(), form(CHAIN))


class SimulateTest(unittest.TestCase):
    def test_absolute_control_in_chain_overlaps_only_with_qt_metrics(self):
        f = L.Form.parse(form(CHAIN))
        self.assertEqual(L.simulate(f.find("Form1"), "design"), [])
        regs = L.regressions(f.find("Form1"))
        self.assertEqual([(r.kind, r.a, r.b) for r in regs], [("OVERLAP", "chkB", "chkC")])


class InferTest(unittest.TestCase):
    def test_absolute_checkbox_is_anchored_under_previous_one(self):
        f = L.Form.parse(form(CHAIN))
        changes, _ = L.infer(f, ["Form1"])
        new = changes["chkC"].new
        self.assertEqual(new["AnchorSideTop.Control"], "chkB")
        self.assertEqual(new["AnchorSideTop.Side"], "asrBottom")
        self.assertEqual(new["BorderSpacing.Top"], "2")
        self.assertEqual(new["AnchorSideLeft.Control"], "chkB")
        L.apply_changes(f, changes)
        self.assertEqual(L.regressions(f.find("Form1")), [])

    def test_label_in_a_row_is_centred_on_its_edit(self):
        body = ctl("lblX", "TLabel", 6, 9, 40, 16, "Caption = 'Name:'") + ctl("edtX", "TEdit", 52, 6, 100, 21)
        f = L.Form.parse(form(body))
        changes, _ = L.infer(f, ["Form1"])
        self.assertEqual(changes["lblX"].new["AnchorSideTop.Control"], "edtX")
        self.assertEqual(changes["lblX"].new["AnchorSideTop.Side"], "asrCenter")
        edt = changes["edtX"].new
        self.assertEqual((edt["AnchorSideTop.Control"], edt["BorderSpacing.Top"]), ("Form1", "6"))
        self.assertEqual((edt["AnchorSideLeft.Control"], edt["AnchorSideLeft.Side"], edt["BorderSpacing.Left"]), ("lblX", "asrBottom", "6"))
        changes, _ = L.infer(f, ["Form1"], chain_rows=False)
        edt = changes["edtX"].new
        self.assertEqual((edt["AnchorSideLeft.Control"], edt["BorderSpacing.Left"]), ("Form1", "52"))

    def test_missing_aktop_in_anchors_is_repaired(self):
        body = (ctl("chkA", "TCheckBox", 6, 6, 100, 18, "AnchorSideLeft.Control = Form1", "AnchorSideTop.Control = Form1",
                    "BorderSpacing.Left = 6", "BorderSpacing.Top = 6")
                + ctl("chkB", "TCheckBox", 6, 24, 100, 18, "AnchorSideLeft.Control = chkA", "AnchorSideTop.Control = chkA",
                      "Anchors = [akLeft]"))
        f = L.Form.parse(form(body))
        changes, _ = L.infer(f, ["Form1"])
        L.apply_changes(f, changes)
        b = block(f.text(), "chkB")
        self.assertIn("AnchorSideTop.Control = chkA\n    AnchorSideTop.Side = asrBottom", b)
        self.assertNotIn("Anchors =", b)
        self.assertNotIn("BorderSpacing.Top", b)

    def test_written_properties_keep_lazarus_order(self):
        f = L.Form.parse(form(CHAIN))
        changes, _ = L.infer(f, ["Form1"])
        L.apply_changes(f, changes)
        b = block(f.text(), "chkC")
        self.assertRegex(b, r"AnchorSideLeft.Control = chkB\n\s*AnchorSideTop.Control = chkB\n\s*AnchorSideTop.Side = asrBottom\n\s*Left = 6")
        self.assertRegex(b, r"Width = 100\n\s*BorderSpacing.Top = 2\n\s*Caption")

    def test_hanging_label_becomes_a_chain_link_below_the_lowest_column(self):
        body = (ctl("chkA", "TCheckBox", 6, 6, 100, 18, "AnchorSideLeft.Control = Form1", "AnchorSideTop.Control = Form1",
                    "BorderSpacing.Left = 6", "BorderSpacing.Top = 6")
                + ctl("chkB", "TCheckBox", 200, 6, 100, 18, "AnchorSideLeft.Control = Form1", "AnchorSideTop.Control = Form1",
                      "BorderSpacing.Left = 200", "BorderSpacing.Top = 6")
                + ctl("chkB2", "TCheckBox", 200, 24, 100, 18, "AnchorSideLeft.Control = chkB", "AnchorSideTop.Control = chkB",
                      "AnchorSideTop.Side = asrBottom")
                + ctl("lblHang", "TLabel", 6, 44, 300, 16, "AnchorSideLeft.Control = Form1", "AnchorSideBottom.Control = edtW",
                      "Anchors = [akLeft, akBottom]", "BorderSpacing.Left = 6", "BorderSpacing.Bottom = 2", "Caption = 'wide'")
                + ctl("edtW", "TEdit", 6, 62, 100, 21))
        text, log, cycles, regs = L.anchor(form(body), ["Form1"])
        self.assertEqual(cycles, [])
        self.assertEqual(regs, [])
        self.assertIn("AnchorSideTop.Control = chkB2", block(text, "lblHang"))
        self.assertNotIn("AnchorSideBottom", block(text, "lblHang"))
        self.assertNotIn("Anchors =", block(text, "lblHang"))
        self.assertIn("AnchorSideTop.Control = lblHang", block(text, "edtW"))


    def test_chain_rows_anchors_edit_after_its_label(self):
        body = (ctl("lblA", "TLabel", 11, 14, 86, 16, "Caption = 'The first after '") + ctl("edtA", "TEdit", 104, 11, 50, 21)
                + ctl("lblB", "TLabel", 192, 14, 103, 16, "Caption = 'the second after '") + ctl("edtB", "TEdit", 312, 11, 50, 21))
        f = L.Form.parse(form(body))
        changes, _ = L.infer(f, ["Form1"], chain_rows=True)
        self.assertEqual((changes["edtA"].new["AnchorSideLeft.Control"], changes["edtA"].new["AnchorSideLeft.Side"],
                          changes["edtA"].new["BorderSpacing.Left"]), ("lblA", "asrBottom", "7"))
        self.assertEqual((changes["lblB"].new["AnchorSideLeft.Control"], changes["lblB"].new["BorderSpacing.Left"]), ("edtA", "38"))
        self.assertEqual((changes["lblA"].new["AnchorSideLeft.Control"], changes["lblA"].new["BorderSpacing.Left"]), ("Form1", "11"))
        L.apply_changes(f, changes)
        self.assertEqual(L.regressions(f.find("Form1")), [])


class AutoSizeContainerTest(unittest.TestCase):
    def test_autosized_groupbox_grows_with_its_children_and_pushes_siblings_down(self):
        gb = ("  object GroupBox1: TGroupBox\n    AnchorSideLeft.Control = Form1\n    AnchorSideTop.Control = Form1\n"
              "    Left = 0\n    Height = 60\n    Top = 0\n    Width = 200\n    AutoSize = True\n    ClientHeight = 33\n    ClientWidth = 190\n"
              + ctl("chkA", "TCheckBox", 6, 0, 100, 18, "AnchorSideLeft.Control = GroupBox1", "AnchorSideTop.Control = GroupBox1", "BorderSpacing.Left = 6").replace("\n  ", "\n    ").replace("  object", "    object", 1)
              + ctl("chkB", "TCheckBox", 6, 18, 100, 18, "AnchorSideLeft.Control = chkA", "AnchorSideTop.Control = chkA", "AnchorSideTop.Side = asrBottom").replace("\n  ", "\n    ").replace("  object", "    object", 1)
              + "  end\n")
        below = ctl("chkC", "TCheckBox", 0, 62, 100, 18, "AnchorSideLeft.Control = Form1", "AnchorSideTop.Control = GroupBox1",
                    "AnchorSideTop.Side = asrBottom", "BorderSpacing.Top = 2")
        f = L.Form.parse(form(gb + below))
        kids, box, cw, ch = L.layout(f.find("Form1"), "qt")
        self.assertEqual(box["GroupBox1"][3], 2 * 24 + L.QT["gb_chrome_h"])
        self.assertEqual(box["chkC"][1], box["GroupBox1"][3] + 2)
        self.assertEqual(L.simulate(f.find("Form1"), "qt"), [])

    def test_autosized_groupbox_keeps_its_constraints_min_width(self):
        gb = ("  object GroupBox1: TGroupBox\n    Left = 0\n    Height = 60\n    Top = 0\n    Width = 200\n    AutoSize = True\n"
              "    ClientHeight = 33\n    ClientWidth = 190\n    Constraints.MinWidth = 200\n"
              + ctl("chkA", "TCheckBox", 6, 0, 100, 18, "AnchorSideLeft.Control = GroupBox1", "AnchorSideTop.Control = GroupBox1", "BorderSpacing.Left = 6").replace("\n  ", "\n    ").replace("  object", "    object", 1)
              + "  end\n")
        f = L.Form.parse(form(gb))
        kids, box, cw, ch = L.layout(f.find("Form1"), "qt")
        self.assertEqual(box["GroupBox1"][2], 200)


class TextWidthTest(unittest.TestCase):
    def test_qt_label_is_wider_than_cocoa_design(self):
        body = ctl("lblA", "TLabel", 14, 50, 90, 16, "Caption = 'Save county to'") + ctl("cmbA", "TComboBox", 118, 46, 75, 19, "Style = csDropDownList", "Items.Strings = (\n      'county'\n    )")
        f = L.Form.parse(form(body))
        self.assertEqual(L.qt_size(f.find("lblA"))[0], 105)      # measured on Qt6: 90 px Cocoa design -> 105 px
        regs = L.regressions(f.find("Form1"))
        self.assertEqual([(r.kind, r.a, r.b) for r in regs], [("TIGHT", "lblA", "cmbA")])


    def test_container_stretched_by_anchors_uses_its_resolved_width(self):
        gb = ("  object GroupBox1: TGroupBox\n    AnchorSideLeft.Control = Form1\n    AnchorSideTop.Control = edtWide\n"
              "    AnchorSideTop.Side = asrBottom\n    AnchorSideRight.Control = edtWide\n    AnchorSideRight.Side = asrBottom\n"
              "    Left = 0\n    Height = 60\n    Top = 30\n    Width = 200\n    Anchors = [akTop, akLeft, akRight]\n    BorderSpacing.Top = 9\n    ClientHeight = 33\n    ClientWidth = 190\n"
              + ctl("chkA", "TCheckBox", 150, 0, 100, 18, "AnchorSideLeft.Control = GroupBox1", "AnchorSideTop.Control = GroupBox1", "BorderSpacing.Left = 150").replace("\n  ", "\n    ").replace("  object", "    object", 1)
              + "  end\n")
        wide = ctl("edtWide", "TEdit", 0, 0, 300, 21, "AnchorSideLeft.Control = Form1", "AnchorSideTop.Control = Form1")
        f = L.Form.parse(form(gb + wide))
        self.assertEqual(L.simulate(f.find("Form1"), "qt"), [])


class CycleTest(unittest.TestCase):
    def test_mutual_anchors_are_reported(self):
        body = (ctl("chkA", "TCheckBox", 6, 6, 100, 18, "AnchorSideTop.Control = chkB", "AnchorSideTop.Side = asrBottom")
                + ctl("chkB", "TCheckBox", 6, 24, 100, 18, "AnchorSideTop.Control = chkA", "AnchorSideTop.Side = asrBottom"))
        f = L.Form.parse(form(body))
        cycles = L.check_cycles(f.find("Form1"))
        self.assertEqual(len(cycles), 1)
        self.assertIn("chkA", cycles[0]); self.assertIn("chkB", cycles[0])


class LintTest(unittest.TestCase):
    def test_collapsed_dropdown_combobox_is_reported_unless_min_width_set(self):
        combo = ctl("cmbX", "TComboBox", 6, 6, 38, 19, "Style = csDropDownList")
        self.assertTrue(any("combo-collapsed" in x and "cmbX" in x for x in L.lint(form(combo), "f.lfm")))
        combo = ctl("cmbX", "TComboBox", 6, 6, 38, 19, "Constraints.MinWidth = 293", "Style = csDropDownList")
        self.assertFalse(any("combo-collapsed" in x for x in L.lint(form(combo), "f.lfm")))

    def test_combobox_with_frozen_cocoa_height_is_reported(self):
        combo = ctl("cmbX", "TComboBox", 6, 6, 293, 19, "AutoSize = False", "Style = csDropDownList")
        self.assertTrue(any("combo-frozen-height" in x and "cmbX" in x for x in L.lint(form(combo), "f.lfm")))
        combo = ctl("cmbX", "TComboBox", 6, 6, 293, 19, "Constraints.MinWidth = 293", "Style = csDropDownList")
        self.assertFalse(any("combo-frozen-height" in x for x in L.lint(form(combo), "f.lfm")))

    def test_right_anchored_autosize_label_is_reported(self):
        lbl = ctl("lblX", "TLabel", 300, 6, 60, 16, "AnchorSideRight.Control = Form1", "AnchorSideRight.Side = asrBottom",
                  "Anchors = [akTop, akRight]", "Caption = 'grows left'")
        out = L.lint(form(lbl), "f.lfm")
        self.assertTrue(any("label-grows-left" in x and "lblX" in x for x in out))

    def test_anchor_side_without_axis_in_anchors_is_reported(self):
        body = ctl("chkA", "TCheckBox", 6, 6, 100, 18) + ctl("chkB", "TCheckBox", 6, 30, 100, 18,
                                                              "AnchorSideTop.Control = chkA", "Anchors = [akLeft]")
        out = L.lint(form(body), "f.lfm")
        self.assertTrue(any("anchors-axis" in x and "chkB" in x for x in out))

    def test_qt_regression_lines_carry_file_and_line(self):
        out = L.lint(form(CHAIN), "f.lfm")
        self.assertTrue(any(x.startswith("f.lfm:") and "qt-regression" in x and "chkC" in x for x in out))


class CliTest(unittest.TestCase):
    def test_vertical_overlap_fails_but_horizontal_only_warns(self):
        import os, tempfile
        row = ctl("lblA", "TLabel", 14, 50, 90, 16, "Caption = 'Save county to'") + ctl("cmbA", "TComboBox", 118, 46, 75, 19, "Style = csDropDownList", "Items.Strings = (\n      'county'\n    )")
        with tempfile.TemporaryDirectory() as d:
            a, b = os.path.join(d, "chain.lfm"), os.path.join(d, "row.lfm")
            open(a, "w").write(form(CHAIN)); open(b, "w").write(form(row))
            self.assertTrue(any("qt-regression" in x for x in L.lint(form(CHAIN), "a")))
            self.assertEqual(L.main(["lint", a]), 1)
            self.assertTrue(any("qt-warning" in x and "TIGHT" in x for x in L.lint(form(row), "b")))
            self.assertFalse(any("qt-regression" in x for x in L.lint(form(row), "b")))
            self.assertEqual(L.main(["lint", b]), 0)

    def test_lint_exit_code_ignores_info_findings(self):
        import os, tempfile
        info_only = ctl("lblX", "TLabel", 300, 6, 60, 16, "AnchorSideRight.Control = Form1", "AnchorSideRight.Side = asrBottom",
                        "Anchors = [akTop, akRight]", "Caption = 'grows left'")
        collapsed = ctl("cmbX", "TComboBox", 6, 6, 38, 19, "Style = csDropDownList")
        with tempfile.TemporaryDirectory() as d:
            a, b = os.path.join(d, "a.lfm"), os.path.join(d, "b.lfm")
            open(a, "w").write(form(info_only)); open(b, "w").write(form(collapsed))
            self.assertEqual(L.main(["lint", a]), 0)
            self.assertEqual(L.main(["lint", b]), 1)


if __name__ == "__main__":
    unittest.main()
