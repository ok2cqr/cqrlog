#!/usr/bin/env python3
"""Layout lint and anchor inference for Lazarus .lfm forms.

Forms saved from the Lazarus designer on macOS carry Cocoa control metrics
(checkbox 18 px, label 16 px, edit 21 px). On Qt/GTK the same controls autosize
taller, so absolutely positioned controls overlap their neighbours. Anchored
controls (AnchorSide* + BorderSpacing) reflow correctly on every widgetset.

  lint   FILE...                 report layout problems, exit 1 when any found
  anchor FILE -c NAME[,NAME...]  infer anchors for absolutely positioned controls
                                 inside the named containers (tab sheets, group
                                 boxes, the form); --write modifies FILE in place
"""
import argparse
import collections
import re
import sys

CONTAINERS = {"TForm", "TTabSheet", "TGroupBox", "TPanel", "TPageControl", "TScrollBox",
              "TRadioGroup", "TNotebook", "TFrame"}
ROW_ANCHOR = ("TEdit", "TComboBox", "TSpinEdit", "TFloatSpinEdit", "TButton", "TColorButton",
              "TColorBox", "TDirectoryEdit", "TFileNameEdit", "TCheckBox", "TRadioButton",
              "TBitBtn", "TSpeedButton", "TTrackBar", "TMaskEdit", "TDateEdit", "TLabeledEdit")
EDIT_LIKE = ("TEdit", "TComboBox", "TSpinEdit", "TFloatSpinEdit", "TColorBox", "TDirectoryEdit",
             "TFileNameEdit", "TMaskEdit", "TDateEdit")
ANCHOR_KEYS = ["AnchorSideLeft.Control", "AnchorSideLeft.Side", "AnchorSideTop.Control",
               "AnchorSideTop.Side", "AnchorSideRight.Control", "AnchorSideRight.Side",
               "AnchorSideBottom.Control", "AnchorSideBottom.Side"]
BS_KEYS = ["BorderSpacing.Left", "BorderSpacing.Top", "BorderSpacing.Right",
           "BorderSpacing.Bottom", "BorderSpacing.Around"]
DEFAULT_ANCHORS = {"akLeft", "akTop"}
# Qt6 metrics measured on Linux screenshots; text is ~17 % wider than the Cocoa design width.
QT = dict(label_line=18, checkbox=24, edit=26, button=26, text=1.17, gb_chrome_w=4, gb_chrome_h=21)

# fuzzy: depends on the estimated Qt text width (heights are exact per widgetset)
Finding = collections.namedtuple("Finding", "kind where a b dx dy detail line fuzzy", defaults=(False,))
INFO_KINDS = {"label-grows-left"}   # reported, but they do not fail the lint
WARN_KINDS = {"qt-warning"}          # horizontal-only regressions: verify on Linux, do not fail
Change = collections.namedtuple("Change", "node new drop")


# ----------------------------------------------------------------------------- parsing
class Node:
    def __init__(self, kind, name, cls, indent, start):
        self.kind, self.name, self.cls, self.indent, self.start = kind, name, cls, indent, start
        self.end = None
        self.entries = []          # [key, [raw lines]] of this object's own properties, file order
        self.children = []
        self.parent = None

    @property
    def props(self):
        return {k: v[0].split(" = ", 1)[1].strip() for k, v in self.entries}

    def geti(self, key, default=0):
        try:
            return int(self.props.get(key))
        except (TypeError, ValueError):
            return default

    def has_geometry(self):
        return "Width" in self.props and self.props.get("Align", "alNone") == "alNone"

    def rect(self):
        return self.geti("Left"), self.geti("Top"), self.geti("Width"), self.geti("Height")

    def anchors(self):
        a = self.props.get("Anchors")
        if a is None:
            return set(DEFAULT_ANCHORS)
        return {x.strip() for x in a.strip("[]").split(",") if x.strip()}

    def caption(self):
        raw = self.props.get("Caption", "''")
        out, i = [], 0
        while i < len(raw):
            if raw[i] == "'":
                j = i + 1
                s = ""
                while j < len(raw):
                    if raw[j] == "'" and j + 1 < len(raw) and raw[j + 1] == "'":
                        s += "'"
                        j += 2
                    elif raw[j] == "'":
                        break
                    else:
                        s += raw[j]
                        j += 1
                out.append(s)
                i = j + 1
            elif raw[i] == "#":
                m = re.match(r"#(\d+)", raw[i:])
                out.append(chr(int(m.group(1))))
                i += len(m.group(0))
            else:
                i += 1
        return "".join(out)

    def where(self):
        n = self
        while n and n.cls not in ("TTabSheet", "TForm"):
            n = n.parent
        return n.name if n else "?"


def _parse(lines):
    root = Node("root", "root", "root", -1, -1)
    stack, nodes, i = [root], [], 0
    while i < len(lines):
        ln = lines[i]
        m = re.match(r"^(\s*)(object|inline|inherited) (\w+): (\w+)", ln)
        if m:
            n = Node(m.group(2), m.group(3), m.group(4), len(m.group(1)), i)
            n.parent = stack[-1]
            stack[-1].children.append(n)
            stack.append(n)
            nodes.append(n)
            i += 1
            continue
        if re.match(r"^\s*item\s*$", ln):
            stack.append(Node("item", "item", "item", 0, i))
            i += 1
            continue
        if re.match(r"^\s*end\s*$", ln):
            stack[-1].end = i
            stack.pop()
            i += 1
            continue
        m = re.match(r"^\s*([\w.]+) = (.*)$", ln)
        if m:
            key, val, j = m.group(1), m.group(2), i
            chunk = [ln]
            if val.endswith(("(", "<", "{")) and not val.endswith("{}"):
                closer = {"(": r"^\s*\)", "<": r"^\s*>", "{": r"\}\s*$"}[val[-1]]
                while True:
                    j += 1
                    chunk.append(lines[j])
                    if re.search(closer, lines[j]):
                        break
            elif val.endswith("+"):
                while lines[j].rstrip().endswith("+"):
                    j += 1
                    chunk.append(lines[j])
            if stack[-1].kind != "item":
                stack[-1].entries.append([key, chunk])
            i = j + 1
            continue
        i += 1
    return root, nodes


class Form:
    def __init__(self, lines):
        self.lines = lines
        self.reparse()

    @classmethod
    def parse(cls, text):
        return cls(text.split("\n"))

    def reparse(self):
        self.root, self.nodes = _parse(self.lines)
        self.byname = {n.name: n for n in self.nodes}

    def find(self, name):
        return self.byname[name]

    def text(self):
        return "\n".join(self.lines)


# ----------------------------------------------------------------------------- simulation
def qt_size(n):
    L, T, W, H = n.rect()
    auto = n.props.get("AutoSize")
    lines_ = n.caption().split("\n")
    if n.cls == "TLabel" and auto != "False":
        H = QT["label_line"] * len(lines_)
        if n.props.get("WordWrap") != "True":
            W = round(W * QT["text"])
    elif n.cls in ("TCheckBox", "TRadioButton") and auto != "False":
        H = QT["checkbox"] + QT["label_line"] * (len(lines_) - 1)
        W = 22 + round(max(W - 18, 0) * QT["text"])
    elif n.cls in EDIT_LIKE and auto != "False":
        H = QT["edit"]
    elif n.cls == "TButton" and auto == "True":
        H = QT["button"]
        W = round(W * QT["text"])
    return W, H


def _chrome(container, metrics):
    """Width/height the container adds around its client area (frame, caption)."""
    if metrics == "qt" and container.cls == "TGroupBox":
        return QT["gb_chrome_w"], QT["gb_chrome_h"]
    return (container.geti("Width") - container.geti("ClientWidth", container.geti("Width")),
            container.geti("Height") - container.geti("ClientHeight", container.geti("Height")))


def _client(container, metrics, size=None):
    """Client area; size overrides the design Width/Height with the values resolved by the parent's layout."""
    dw, dh = _chrome(container, metrics)
    w, h = size if size else (container.geti("Width"), container.geti("Height"))
    return w - dw, h - dh


def autosizes(container):
    """True when the container sizes itself to its children (no child may then hang on its right/bottom edge)."""
    if container.props.get("AutoSize") != "True" or container.cls not in ("TGroupBox", "TPanel"):
        return False
    for k in container.children:
        if k.kind == "item":
            continue
        a = k.anchors()
        if ("akRight" in a and k.props.get("AnchorSideRight.Control") == container.name) or \
           ("akBottom" in a and k.props.get("AnchorSideBottom.Control") == container.name):
            return False
    return True


def preferred_size(container, metrics):
    kids, box, cw, ch = layout(container, metrics)
    dw, dh = _chrome(container, metrics)
    return cw + dw, ch + dh


def layout(container, metrics, size=None):
    """Resolve child rectangles of one container the way LCL anchoring does."""
    kids = [k for k in container.children if k.kind != "item" and k.has_geometry() and k.props.get("Visible") != "False"]
    cw, ch = _client(container, metrics, size)
    box = {}
    for k in kids:
        L, T, W, H = k.rect()
        if metrics == "qt":
            W, H = qt_size(k)
        if autosizes(k):
            W, H = preferred_size(k, metrics)
        box[k.name] = [L, T, W, H]
    byname = {k.name: k for k in kids}
    opposite = {"Left": "Right", "Right": "Left", "Top": "Bottom", "Bottom": "Top"}

    def space(n, side):
        return n.geti("BorderSpacing.Around") + n.geti("BorderSpacing." + side)

    def sidepos(k, kind):
        ref = k.props.get(f"AnchorSide{kind}.Control")
        side = k.props.get(f"AnchorSide{kind}.Side", "asrTop")
        horiz = kind in ("Left", "Right")
        if ref == container.name:
            rl, rt, rw, rh, isparent = 0, 0, cw, ch, True
        elif ref in box:
            (rl, rt, rw, rh), isparent = box[ref], False
        else:
            return None
        sp = space(k, kind)
        if side == "asrCenter":
            centre = rl + rw // 2 if horiz else rt + rh // 2
            own = box[k.name][2] if horiz else box[k.name][3]
            return centre - own // 2 if kind in ("Left", "Top") else centre + own // 2
        if side == "asrTop":
            pos = rl if horiz else rt
            if not isparent and kind in ("Right", "Bottom"):
                sp = max(sp, space(byname[ref], opposite[kind]))
        else:
            pos = rl + rw if horiz else rt + rh
            if not isparent and kind in ("Left", "Top"):
                sp = max(sp, space(byname[ref], opposite[kind]))
        return pos + sp if kind in ("Left", "Top") else pos - sp

    for _ in range(len(kids) + 3):
        for k in kids:
            a = k.anchors()
            L, T, W, H = box[k.name]
            lp = sidepos(k, "Left") if "akLeft" in a and "AnchorSideLeft.Control" in k.props else None
            rp = sidepos(k, "Right") if "akRight" in a and "AnchorSideRight.Control" in k.props else None
            tp = sidepos(k, "Top") if "akTop" in a and "AnchorSideTop.Control" in k.props else None
            bp = sidepos(k, "Bottom") if "akBottom" in a and "AnchorSideBottom.Control" in k.props else None
            if lp is not None and rp is not None:
                L, W = lp, max(0, rp - lp)
            elif lp is not None:
                L = lp
            elif rp is not None:
                L = rp - W
            if tp is not None and bp is not None:
                T, H = tp, max(0, bp - tp)
            elif tp is not None:
                T = tp
            elif bp is not None:
                T = bp - H
            box[k.name] = [L, T, W, H]
    if autosizes(container) and kids:
        dw, dh = _chrome(container, metrics)
        cw = max([b[0] + b[2] + byname[n].geti("BorderSpacing.Right") + byname[n].geti("BorderSpacing.Around") for n, b in box.items()]
                 + [container.geti("Constraints.MinWidth") - dw])
        ch = max([b[1] + b[3] + byname[n].geti("BorderSpacing.Bottom") + byname[n].geti("BorderSpacing.Around") for n, b in box.items()]
                 + [container.geti("Constraints.MinHeight") - dh])
    return kids, box, cw, ch


def simulate(container, metrics, size=None):
    """Overlaps between siblings and children leaving the client area, recursively.
    Nested containers are simulated at the size their own anchors resolved to."""
    out = []
    kids, box, cw, ch = layout(container, metrics, size)
    where = f"{container.where()}/{container.name}"
    for i, a in enumerate(kids):
        al, at, aw, ah = box[a.name]
        if al + aw > cw + 2 or at + ah > ch + 2:
            out.append(Finding("CLIP", where, a.name, "", max(al + aw - cw, 0), max(at + ah - ch, 0),
                               f"{a.cls} ends at {al + aw}x{at + ah}, client {cw}x{ch}", a.start + 1))
        for b in kids[i + 1:]:
            bl, bt, bw, bh = box[b.name]
            iw = min(al + aw, bl + bw) - max(al, bl)
            ih = min(at + ah, bt + bh) - max(at, bt)
            if iw > 2 and ih > 2 and not (a.cls in CONTAINERS and b.cls in CONTAINERS):
                out.append(Finding("OVERLAP", where, a.name, b.name, iw, ih,
                                   f"{a.cls} x {b.cls} by {iw}x{ih} px", max(a.start, b.start) + 1))
    for k in container.children:
        if k.kind != "item" and k.cls in CONTAINERS and k.cls != "TRadioGroup":
            out.extend(simulate(k, metrics, tuple(box[k.name][2:4]) if k.name in box else None))
    return out


def tight_pairs(container):
    """Row neighbours whose design gap (>= 6 px) shrinks below 3 px with Qt metrics."""
    out = []
    kids, dbox, _, _ = layout(container, "design")
    _, qbox, _, _ = layout(container, "qt")
    where = f"{container.where()}/{container.name}"
    for a in kids:
        for b in kids:
            if a is b or a.cls in CONTAINERS or b.cls in CONTAINERS:
                continue
            al, at, aw, ah = dbox[a.name]
            bl, bt, bw, bh = dbox[b.name]
            same_row = min(at + ah, bt + bh) - max(at, bt) > 2
            dgap = bl - (al + aw)
            if same_row and 6 <= dgap:
                ql, qt_, qw, qh = qbox[a.name]
                qgap = qbox[b.name][0] - (ql + qw)
                if qgap < 3 and min(qt_ + qh, qbox[b.name][1] + qbox[b.name][3]) - max(qt_, qbox[b.name][1]) > 2:
                    out.append(Finding("TIGHT", where, a.name, b.name, dgap - qgap, 0,
                                       f"{a.cls} x {b.cls}: design gap {dgap} px shrinks to {qgap} px", max(a.start, b.start) + 1, True))
    for k in container.children:
        if k.kind != "item" and k.cls in CONTAINERS and k.cls != "TRadioGroup":
            out.extend(tight_pairs(k))
    return out


def _design_rows(container):
    """(where, a, b) of sibling pairs that already share a row in the design; recursive."""
    out = set()
    kids, box, _, _ = layout(container, "design")
    where = f"{container.where()}/{container.name}"
    for i, a in enumerate(kids):
        for b in kids[i + 1:]:
            at, ah, bt, bh = box[a.name][1], box[a.name][3], box[b.name][1], box[b.name][3]
            if min(at + ah, bt + bh) - max(at, bt) > 2:
                out.add((where, a.name, b.name))
    for k in container.children:
        if k.kind != "item" and k.cls in CONTAINERS and k.cls != "TRadioGroup":
            out |= _design_rows(k)
    return out


def regressions(container):
    """Problems that appear with Qt metrics but not with the design (Cocoa) metrics.
    A finding is fuzzy when only the estimated text width causes it: an overlap of
    controls that already share a row, or clipping at the right edge."""
    base = {(f.kind, f.where, f.a, f.b): (f.dx, f.dy) for f in simulate(container, "design")}
    rows = _design_rows(container)
    out = []
    for f in simulate(container, "qt"):
        k = (f.kind, f.where, f.a, f.b)
        if k not in base or (f.kind == "CLIP" and (f.dx - base[k][0] >= 8 or f.dy - base[k][1] >= 8)):
            fuzzy = (f.kind == "OVERLAP" and (f.where, f.a, f.b) in rows) or (f.kind == "CLIP" and f.dy == 0)
            out.append(f._replace(fuzzy=fuzzy))
    return out + tight_pairs(container)


# ----------------------------------------------------------------------------- inference
def infer(form, names, chain_rows=True):
    """Anchor absolutely positioned controls inside the named containers.

    Vertical: a control goes under the nearest sibling above its row (asrBottom +
    gap); a label sharing a row with an edit-like control is centred on it; a label
    hanging below-anchored (akBottom) on an absolute control becomes a normal link
    of the chain, because the control's new BorderSpacing.Top would otherwise push
    it up. Horizontal: the left edge aligns to the sibling above with the same
    Left, otherwise it follows the previous control in the row (asrBottom + gap),
    because Qt text is about 15 % wider than the Cocoa design and a control at a
    fixed offset would overlap the label. chain_rows=False keeps the absolute
    offset from the parent instead; use it for containers whose labels get a
    runtime caption (font names, paths) that would push their neighbours around.
    Existing anchors are never touched.
    """
    changes, log = {}, []

    def walk(container):
        kids = [k for k in container.children if k.kind != "item" and k.has_geometry()]
        vp = {k.name: dict(k.props) for k in kids}      # props including pending changes
        geo = {k.name: k.rect() for k in kids}
        L = lambda k: geo[k.name][0]
        T = lambda k: geo[k.name][1]
        R = lambda k: geo[k.name][0] + geo[k.name][2]
        B = lambda k: geo[k.name][1] + geo[k.name][3]
        C = lambda k: T(k) + geo[k.name][3] / 2

        def anchors_of(k):
            a = vp[k.name].get("Anchors")
            if isinstance(a, set):
                return set(a)
            return k.anchors() if a is None or a == k.props.get("Anchors") else set(x.strip() for x in a.strip("[]").split(","))

        def decide(k, new, drop):
            c = changes.get(k.name, Change(k, {}, set()))
            c.new.update(new)
            c.drop.update(drop)
            for key in drop:
                c.new.pop(key, None)
                vp[k.name].pop(key, None)
            vp[k.name].update(new)
            changes[k.name] = c

        rows = []
        for k in sorted(kids, key=C):
            for row in rows:
                if k.cls not in CONTAINERS and abs(C(k) - sum(C(x) for x in row) / len(row)) <= 5:
                    row.append(k)
                    break
            else:
                rows.append([k])
        rowof = {k.name: row for row in rows for k in row}

        # labels hanging (akBottom) on a control that is itself absolute become chain links
        for k in kids:
            a = anchors_of(k)
            ref = vp[k.name].get("AnchorSideBottom.Control")
            if "akBottom" in a and "akTop" not in a and ref in vp:
                ra = anchors_of(form.find(ref))
                ref_vert = ("akTop" in ra and "AnchorSideTop.Control" in vp[ref]) or ("akBottom" in ra and "AnchorSideBottom.Control" in vp[ref])
                if not ref_vert:
                    decide(k, {"Anchors": (a - {"akBottom"}) | {"akTop"}},
                           {"AnchorSideBottom.Control", "AnchorSideBottom.Side", "BorderSpacing.Bottom"})
                    log.append(f"{k.name}: no longer hangs on {ref}, joins the chain")

        for k in sorted(kids, key=lambda k: (T(k), L(k))):
            p, a, new, drop = vp[k.name], anchors_of(k), {}, set()
            vert = ("akTop" in a and "AnchorSideTop.Control" in p) or ("akBottom" in a and "AnchorSideBottom.Control" in p)
            horiz = ("akLeft" in a and "AnchorSideLeft.Control" in p) or ("akRight" in a and "AnchorSideRight.Control" in p)
            if not vert and not a & {"akTop", "akBottom"}:
                a.add("akTop")
                new["Anchors"] = a
            if not horiz and not a & {"akLeft", "akRight"}:
                a.add("akLeft")
                new["Anchors"] = a
            if not vert and "akTop" in a:
                row = rowof[k.name]
                cand = [x for x in row if x.cls in ROW_ANCHOR] or [x for x in row if x.cls not in CONTAINERS] or row
                ra = min(cand, key=L)
                if ra is not k and ra.cls not in CONTAINERS and k.cls not in CONTAINERS:
                    new["AnchorSideTop.Control"], new["AnchorSideTop.Side"] = ra.name, "asrCenter"
                    drop.add("BorderSpacing.Top")
                    log.append(f"{k.name}: top centred on {ra.name}")
                else:
                    span_l, span_r = min(L(x) for x in row), max(R(x) for x in row)
                    above = [s for s in kids if s is not k and s not in row and B(s) <= T(k) + 2]
                    overlapping = [s for s in above if L(s) < span_r and R(s) > span_l]
                    pool = overlapping or above
                    if pool:
                        mb = max(B(s) for s in pool)
                        best = sorted([s for s in pool if B(s) >= mb - 3], key=lambda s: (s.cls not in ROW_ANCHOR, -B(s)))[0]
                        gap = max(0, T(k) - B(best))
                        new["AnchorSideTop.Control"], new["AnchorSideTop.Side"] = best.name, "asrBottom"
                        if gap:
                            new["BorderSpacing.Top"] = str(gap)
                        else:
                            drop.add("BorderSpacing.Top")
                        log.append(f"{k.name}: top under {best.name} (+{gap})")
                    else:
                        new["AnchorSideTop.Control"] = container.name
                        drop.add("AnchorSideTop.Side")
                        if T(k) > 0:
                            new["BorderSpacing.Top"] = str(T(k))
                        else:
                            drop.add("BorderSpacing.Top")
                        log.append(f"{k.name}: top to parent (+{max(T(k), 0)})")
            if not horiz and "akLeft" in a:
                col = [s for s in kids if s is not k and B(s) <= T(k) + 2 and abs(L(s) - L(k)) <= 2]
                prev = [s for s in rowof[k.name] if s is not k and R(s) <= L(k) + 2] if chain_rows else []
                if col:
                    best = max(col, key=B)
                    new["AnchorSideLeft.Control"] = best.name
                    drop.update({"AnchorSideLeft.Side", "BorderSpacing.Left"})
                    log.append(f"{k.name}: left aligned to {best.name}")
                elif prev:
                    best = max(prev, key=R)
                    gap = max(0, L(k) - R(best))
                    new["AnchorSideLeft.Control"], new["AnchorSideLeft.Side"] = best.name, "asrBottom"
                    if gap:
                        new["BorderSpacing.Left"] = str(gap)
                    else:
                        drop.add("BorderSpacing.Left")
                    log.append(f"{k.name}: left after {best.name} (+{gap})")
                else:
                    new["AnchorSideLeft.Control"] = container.name
                    drop.add("AnchorSideLeft.Side")
                    if L(k) > 0:
                        new["BorderSpacing.Left"] = str(L(k))
                    else:
                        drop.add("BorderSpacing.Left")
                    log.append(f"{k.name}: left to parent (+{max(L(k), 0)})")
            if new or drop:
                decide(k, new, drop)
        for k in kids:
            if k.cls in CONTAINERS and k.cls != "TRadioGroup":
                walk(k)

    for name in names:
        walk(form.find(name))
    return changes, log


def apply_changes(form, changes):
    """Rewrite the changed objects, keeping the property order Lazarus uses."""
    for change in sorted(changes.values(), key=lambda c: -c.node.start):
        node, new, drop = change
        ind = " " * (node.indent + 2)
        existing = {e[0]: e for e in node.entries}
        keep = [e for e in node.entries if e[0] not in new and e[0] not in drop]
        anch = [[k, [f"{ind}{k} = {new[k]}"]] if k in new else existing[k]
                for k in ANCHOR_KEYS if k in new or (k in existing and k not in drop)]
        bs = [[k, [f"{ind}{k} = {new[k]}"]] if k in new else existing[k]
              for k in BS_KEYS if k in new or (k in existing and k not in drop)]
        rest = [e for e in keep if e[0] not in ANCHOR_KEYS and e[0] not in BS_KEYS and e[0] != "Anchors"]
        pos = next((i for i, e in enumerate(rest) if e[0] == "Width"), -1) + 1
        aset = new.get("Anchors", node.anchors() if "Anchors" in existing else None)
        if aset is not None and aset != DEFAULT_ANCHORS:
            txt = ", ".join(x for x in ("akTop", "akLeft", "akRight", "akBottom") if x in aset)
            rest.insert(pos, ["Anchors", [f"{ind}Anchors = [{txt}]"]])
            pos += 1
        while pos < len(rest) and rest[pos][0] == "AutoSize":
            pos += 1
        body = anch + rest[:pos] + bs + rest[pos:]
        first = node.start + 1
        last = min([c.start for c in node.children] + [node.end])
        form.lines[first:last] = [ln for e in body for ln in e[1]]
    form.reparse()


def check_cycles(container):
    out = []
    kids = {k.name: k for k in container.children if k.kind != "item"}
    for axis, keys in (("vertical", ("AnchorSideTop.Control", "AnchorSideBottom.Control")),
                       ("horizontal", ("AnchorSideLeft.Control", "AnchorSideRight.Control"))):
        edges = {n: [k.props[key] for key in keys if k.props.get(key) in kids] for n, k in kids.items()}
        state = {}

        def dfs(n, path):
            state[n] = 1
            path.append(n)
            for m in edges.get(n, []):
                if state.get(m) == 1:
                    out.append(f"{axis} anchor cycle in {container.name}: {' -> '.join(path + [m])}")
                elif m not in state:
                    dfs(m, path)
            path.pop()
            state[n] = 2

        for n in kids:
            if n not in state:
                dfs(n, [])
    for k in kids.values():
        if k.cls in CONTAINERS:
            out.extend(check_cycles(k))
    return out


def anchor(text, names, chain_rows=True):
    """Infer and apply anchors. Returns the new text, the log, anchor cycles and
    every overlap/clip (design or Qt metrics) that the original design did not have."""
    original = Form.parse(text)
    base = {(f.kind, f.where, f.a, f.b) for n in names for f in simulate(original.find(n), "design")}
    form = Form.parse(text)
    changes, log = infer(form, names, chain_rows)
    apply_changes(form, changes)
    cycles = [c for n in names for c in check_cycles(form.find(n))]
    regs, seen = [], set()
    for n in names:
        for metrics in ("design", "qt"):
            for f in simulate(form.find(n), metrics):
                k = (f.kind, f.where, f.a, f.b)
                if k not in base and k not in seen:
                    seen.add(k)
                    regs.append(f)
    return form.text(), log, cycles, regs


# ----------------------------------------------------------------------------- lint
def lint(text, filename=""):
    form = Form.parse(text)
    out = []

    def emit(node, kind, msg):
        out.append(f"{filename}:{node.start + 1}: {kind}: {node.name}: {msg}")

    for n in form.nodes:
        p, a = n.props, n.anchors()
        if (n.cls == "TComboBox" and n.geti("Width") <= 40 and p.get("Style") == "csDropDownList"
                and "Items.Strings" not in p and n.geti("Constraints.MinWidth") <= 40):
            emit(n, "combo-collapsed", "dropdown without design-time items collapsed to the Cocoa minimum width; restore Width and add Constraints.MinWidth")
        if n.cls == "TComboBox" and p.get("AutoSize") == "False" and n.geti("Height") < 24:
            emit(n, "combo-frozen-height", "AutoSize = False freezes the Cocoa height, too small for Qt/GTK; use Constraints.MinWidth to protect the width instead")
        if n.cls == "TLabel" and "akRight" in a and "akLeft" not in a and "AnchorSideRight.Control" in p and p.get("AutoSize") != "False":
            emit(n, "label-grows-left", "right-anchored autosized label grows leftwards into its neighbours on wider fonts")
        if ("AnchorSideTop.Control" in p or "AnchorSideBottom.Control" in p) and not a & {"akTop", "akBottom"}:
            emit(n, "anchors-axis", "AnchorSideTop/Bottom is set but Anchors contains neither akTop nor akBottom, so the control is positioned absolutely")
        if ("AnchorSideLeft.Control" in p or "AnchorSideRight.Control" in p) and not a & {"akLeft", "akRight"}:
            emit(n, "anchors-axis", "AnchorSideLeft/Right is set but Anchors contains neither akLeft nor akRight")
    for top in form.root.children:
        for f in regressions(top):
            kind = "qt-warning" if f.fuzzy else "qt-regression"
            out.append(f"{filename}:{f.line}: {kind}: {f.where}: {f.kind} {f.a}{' x ' + f.b if f.b else ''}: {f.detail}")
    return out


# ----------------------------------------------------------------------------- cli
def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    pl = sub.add_parser("lint", help="report layout problems in .lfm files")
    pl.add_argument("files", nargs="+")
    pa = sub.add_parser("anchor", help="infer anchors for absolutely positioned controls")
    pa.add_argument("file")
    pa.add_argument("-c", "--containers", required=True, help="comma separated object names (tab sheets, group boxes, form)")
    pa.add_argument("--no-chain-rows", dest="chain_rows", action="store_false", help="keep absolute left offsets instead of chaining after the previous control in the row (for labels with runtime captions)")
    pa.add_argument("--write", action="store_true", help="modify the file in place")
    args = ap.parse_args(argv)
    if args.cmd == "lint":
        errors = warns = infos = 0
        for fn in args.files:
            for line in lint(open(fn, encoding="utf-8").read(), fn):
                kind = line.split(": ")[1]
                if kind in INFO_KINDS:
                    infos += 1
                    print("info: " + line)
                elif kind in WARN_KINDS:
                    warns += 1
                    print("warning: " + line)
                else:
                    errors += 1
                    print(line)
        print(f"{errors} problem(s), {warns} warning(s) to verify on Linux, {infos} info")
        return 1 if errors else 0
    text = open(args.file, encoding="utf-8").read()
    new_text, log, cycles, regs = anchor(text, args.containers.split(","), args.chain_rows)
    print("\n".join(log) or "nothing to anchor")
    for c in cycles:
        print("CYCLE:", c)
    for r in regs:
        print(f"remaining {r.kind} {r.where}: {r.a}{' x ' + r.b if r.b else ''}: {r.detail}")
    if cycles:
        print("refusing to write: anchor cycle")
        return 2
    if args.write:
        open(args.file, "w", encoding="utf-8").write(new_text)
        print(f"written: {args.file}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
