#!/bin/sh
# Builds the DXCC table files that TDxccTable / Tseznam consume, exactly the way
# CQRLOG builds them at runtime.
#
# CQRLOG has two different builders that produce two DIFFERENT country.tab files:
#
#   dData.pas:1057   TdmData.PrepareDXCCData
#       Runs on first start.  Plain concatenation, no '%' expansion.
#       -> country-plain.tab
#
#   fImportProgress.pas:344-351   manual "Import DXCC data"
#       Same concatenation, then every line starting with '%' is appended again
#       26 times with the '%' replaced by 'A'..'Z'.
#       -> country-expanded.tab
#
# Both variants exist in the field, so the tests run against both.
#
# Line endings are normalised to LF because both builders round-trip the data
# through TStringList, which rewrites them on save.

set -eu

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
cty="$repo/ctyfiles"
out="$here/../tests/data/generated"

mkdir -p "$out"

for f in Country.tab CallResolution.tbl AreaOK1RR.tbl CountryDel.tab \
         Exceptions.tab Ambiguous.tbl; do
    if [ ! -f "$cty/$f" ]; then
        echo "mkdxccdata.sh: missing $cty/$f" >&2
        exit 1
    fi
done

strip_cr() { tr -d '\r' < "$1"; }

# --- country-plain.tab : dData.pas:1057 -------------------------------------
{
    strip_cr "$cty/Country.tab"
    strip_cr "$cty/CallResolution.tbl"
    strip_cr "$cty/AreaOK1RR.tbl"
} > "$out/country-plain.tab"

# --- country-expanded.tab : fImportProgress.pas:344-351 ---------------------
# The expansion loop iterates over the list as it was BEFORE the loop started
# (Pascal evaluates the for-bound once), so the generated lines are appended
# after all original lines and are not themselves re-expanded.
{
    cat "$out/country-plain.tab"
    awk '/^%/ {
        rest = substr($0, 2)
        for (i = 65; i <= 90; i++) printf "%c%s\n", i, rest
    }' "$out/country-plain.tab"
} > "$out/country-expanded.tab"

# --- country_del.tab : dData.pas:1074 ---------------------------------------
strip_cr "$cty/CountryDel.tab" > "$out/country_del.tab"

# --- exceptions.tab / ambiguous.tab : dData.pas:1076-1079 -------------------
# Straight copies.  These never reach the table parser; they feed the
# callsign-splitting layer (dDXCC.LoadExceptionArray / LoadAmbiguousArray).
strip_cr "$cty/Exceptions.tab" > "$out/exceptions.tab"
strip_cr "$cty/Ambiguous.tbl"  > "$out/ambiguous.tab"

for f in country-plain.tab country-expanded.tab country_del.tab \
         exceptions.tab ambiguous.tab; do
    printf '%-24s %8d lines  %10d bytes\n' \
        "$f" "$(wc -l < "$out/$f")" "$(wc -c < "$out/$f")"
done
