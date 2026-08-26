# dxcc-parser

A modernised replacement for the DXCC prefix lookup engine — `src/odbec.pas`
and `src/znacmech.pas` — built **beside** the originals rather than in place.

This engine is now **live**: `dDXCC.pas` and `dDXCluster.pas` resolve every
callsign through `TDxccTable` + `TDxccResolver`, and `src/cqrlog.lpi` carries
`dxcc-parser` on its unit path. `src/odbec.pas` and `src/znacmech.pas` stay in
the project and in `cqrlog.lpr` — nothing calls them any more, but `legacy/`
reaches them by symlink, which is what keeps the old-vs-new comparison
runnable against the code that actually ships.

The point of the preceding stage was to prove the replacement resolves
callsigns *identically* before anything depended on it. It did; see below.

## Running it

```sh
cd src/dxcc-parser
make test        # whole suite, old-vs-new matrix sampled   (~20 s)
make test-full   # whole suite, old-vs-new matrix exhaustive
make diff        # only the old-vs-new comparison, exhaustive

make logdiff CSV=~/export.csv   # both engines over a real log, see below
make logdiff-selfcheck          # prove logdiff can see a difference
make bench ADIF='~/a.adi ~/b.adi'  # time both engines over the same callsigns
```

Needs `fpc` only — no Lazarus, no LCL, no MySQL. Test fixtures are generated
from `../../ctyfiles` on first build by `tools/mkdxccdata.sh`.

## Layout

| Path | What it is |
|---|---|
| `uDxccCollation.pas` | sort order for the table index — replaces `odbec.pas` |
| `uDxccPattern.pas` | pattern matching, pure functions |
| `uDxccEntry.pas` | one description parsed into named fields |
| `uDxccTable.pas` | the table itself — replaces `Tseznam` |
| `uDxccSuffixRules.pas` | `exceptions.tab` / `ambiguous.tab` |
| `uDxccResolver.pas` | callsign splitting — replaces `CoVyhodnocovat` |
| `uDxccLimits.pas` | the format's length limits, and why they are kept |
| `legacy/` | symlinks to the two original units, so they compile from source |
| `tests/` | the suite; `uLegacyTable`/`uModernTable` put both engines behind one interface, `uLegacySplitter` is a transcription of the original splitter |
| `tools/mkdxccdata.sh` | rebuilds the fixtures the way CQRLOG builds `country.tab` |
| `tools/dumpcollation.lpr` | prints the collation table |
| `tools/logdiff.lpr` | runs both engines over a real QSO export — see below |
| `tools/bench.lpr` | times both engines over the same callsigns, layer by layer (load / split / find / full `id_country` path); built with `-O2` like the application |

## Which files does the parser actually read?

Only **two**. It is worth being precise, because four files are involved in
resolving a callsign and they are read by different layers:

| File | Built from | Read by | Into |
|---|---|---|---|
| `country.tab` | `Country.tab` + `CallResolution.tbl` + `AreaOK1RR.tbl` | **the parser** (`Tseznam` / `TDxccTable`) | the indexed table |
| `country_del.tab` | `CountryDel.tab` | **the parser** (a second instance) | the deleted-entities table |
| `exceptions.tab` | `Exceptions.tab` | `dDXCC.LoadExceptionArray` (`dDXCC.pas:1038`) | a plain string array |
| `ambiguous.tab` | `Ambiguous.tbl` | `dDXCC.LoadAmbiguousArray` (`dDXCC.pas:1020`) | a plain string array |

So `CallResolution.tbl` is not read on its own at all — it is concatenated into
`country.tab` before the parser ever sees it, which is why an exact `=OK1ABC`
entry and an area pattern `OK#` compete inside one index.

`exceptions.tab` and `ambiguous.tab` never reach the parser. They belong to the
*callsign-splitting* layer: `IsException` decides whether a two-letter suffix
should be ignored (`DL1ABC/LH` is still Germany), and `IsAmbiguous` flags
prefixes that cannot be resolved from the prefix alone. Both are consumed by
`CoVyhodnocovat`, which still lives in `dDXCC.pas` and is not part of this
work yet.

`dDXCluster` loads `exceptions.tab` too (`dDXCluster.pas:1102`) but not
`ambiguous.tab` — one of several ways the two copies have drifted.

## Argentina, and why it is the hard case

Argentine provinces are encoded in the **fourth character** of the callsign,
not in a prefix: `LU1FAA` is Santa Fe, `LU1HAA` is Córdoba, `LU1AAA` is Buenos
Aires. Operating from elsewhere is signalled with a single trailing letter, and
`CoVyhodnocovat` (`dDXCC.pas:517-529`, the branch commented *"nesmime
zapomenout na chudaky Argentince"*) turns that into a lookup key by
**overwriting character 4**:

```
LU1AAA + /Z  ->  LU1ZAA
```

`LU#Z` is not another province — it is **Antarctica**, a separate DXCC entity.
Getting this wrong moves a QSO to the wrong country and changes the DXCC
standings, which is why `tArgentina` covers it specifically, including the
`LU`/`LW` twins, the `[A-O]` / `[P-Z]` splits for Chaco/Formosa and Santa
Cruz/Tierra del Fuego, the named Antarctic bases, and a date-scoped exact
entry (`=LU1ZBM`, valid only during 2004) that stops winning once its window
closes.

Some portable forms are listed verbatim with the slash (`=LU2ERA/Z`,
`=LU8DBS/Z`), so `CoVyhodnocovat`'s first move — try the whole string as an
exact match (`dDXCC.pas:463`) — resolves those with no rewriting at all.

### The one deliberate behaviour change: Argentine suffix letters

`CoVyhodnocovat` only treats a single-letter suffix as a province for letters
in `['A'..'D','E','H','J','L'..'V','X'..'Z']`. That set omits **F, G, I, K and
W**, because each is a major DXCC prefix in its own right — F=France,
G=England, I=Italy, W/K=United States — and `DL1ABC/F` was meant to mean
France.

All five are also Argentine provinces. Two of them the country files already
rescue with explicit slash patterns in `AreaOK1RR.tbl`:

```
L[O-W][1-9]%/W  L[O-W][1-9]%%/W  L[O-W][1-9]%%%/W        -> Chubut (CH)
L[O-W][1-9]%/X[A-O] ...                                  -> Santa Cruz (SC)
L[O-W][1-9]%/X[P-Z] ...                                  -> Tierra del Fuego (TF)
```

Those are found by the exact-match attempt at the top of the splitter, before
any rewriting, so `/W` and `/X` were never broken — and `TDxccResolver` leaves
them exactly as they were. The `/X` pair is also a good argument for keeping
the tables ahead of the rewrite: it expresses a Santa Cruz / Tierra del Fuego
split that a character swap cannot.

**F, G, I and K got no such entry**, so those four fall to the generic branch
at `dDXCC.pas:533` and lose the province: `LU1AAA/F` resolves as plain
Argentina rather than Santa Fe. A second, smaller gap sits just above: the
`/M` and `/P` shortcut tests only `Pos('LU',...)`, so the ten companion
prefixes lose Mendoza and San Juan — `LW1AAA/M` resolves as plain Buenos
Aires.

That generic branch is worth following, because it does **not** do what the
comment above it implies. It sets the key to the bare suffix (`'F'`) and would
indeed land on France — but the very next statement probes
`Copy(prefix,1,2) + '/' + suffix`, i.e. `LU/F`, in **prefix** mode, where a
callsign may be longer than the pattern. `LU` is itself a mark, so the probe
hits, the key becomes `LU/F`, and the answer is generic Argentina. The same
mechanism catches every prefix that appears in the tables on its own:
`DL1ABC/F` resolves through `DL/F` as Germany, not France.

So the ADIF number never actually moved, and neither does the fix move it: all
Argentine provinces share ADIF 100. What changes is the country string — the
province — which is what the log shows and what the DOK/province statistics
count. `logdiff` (below) confirmed this on a 58 184-QSO log: the intended
change is real but produced **zero** ADIF differences.

`TDxccResolver` fixes both, by testing for an Argentine prefix first and across
the whole alphabet. `tSplitting.OnlyArgentineCallsignsDiffer` sweeps every
Argentine prefix and several foreign ones against every single-character
suffix and asserts that **nothing outside that shape changed** — the fix is
narrow by construction, not by hope.

## Which `country.tab`?

CQRLOG builds this file in two places and **they do not agree**:

- `dData.pas:1057` (`PrepareDXCCData`, first run) concatenates `Country.tab`,
  `CallResolution.tbl` and `AreaOK1RR.tbl` as they are.
- `fImportProgress.pas:344-351` (manual *Import DXCC data*) does the same and
  then expands every line starting with `%` into 26 copies, one per leading
  letter `A`..`Z`.

There are 204 such lines, all guest-operator patterns of the shape
`%%%%/B[A-LRSTYZ]0[A-F]%`, so the manual import adds 5304 lines. A `%`-leading
pattern sorts above every alphanumeric and is therefore unreachable by any
scan keyed on the callsign's first character — which means the two files
resolve some callsigns differently. `OK1A/BA0AX` is one; the test
`PlainAndExpandedDifferOnGuestOperatorCalls` pins it down.

**The expanded form is the reference**, since that is what a user has after
importing country files. Both are tested; `uTestData.CanonicalTable` points at
the expanded one.

## Behaviour that is deliberately preserved

The rule for this stage is equivalence, not repair. Every oddity below is
reproduced on purpose and covered by a test, because each one can change which
country a callsign resolves to. Fixing any of them is separate work with its
own evidence.

| Where | What |
|---|---|
| `znacmech.pas:853` `presnejsivyznam` | The specificity walk starts at index **0**, which on a shortstring is the length byte, not a character. A 35-character pattern therefore compares as `#` and a 37-character one as `%`. It also stops at `Length-1`, so the final character is never examined. `uDxccPattern.LegacyCharAt` reproduces both. |
| `odbec.pas:68` `pripravbec` | Scans with `x < 254` where 255 was meant, so bytes `#254` and `#255` share rank 254. Reproduced via `HighestScannedRank`. |
| `odbec.pas:83` `string2bec` | Strips a leading `=` **before** building the sort key, so `=OK1ABC` and `OK1ABC` sort together and compete. The range scan depends on this. |
| `znacmech.pas:676` `setrid_znacky` | A **stable** sort. `Find` keeps the first of two equally good candidates, so the order of marks with identical keys decides the winner. `TDxccTable.SortMarks` is a stable merge sort for this reason — `TFPList.Sort` is quicksort and would silently change results. |
| `znacmech.pas:41-43` | Marks are cut to 40 characters and descriptions to 250. The current `CallResolution.tbl` really does contain a 42-character token, so the truncation is live. |
| `znacmech.pas:477` `odesli` | A validity window holding two space-separated periods becomes two records. No current line does this, but the loader has always supported it. |
| `znacmech.pas:401-406` `pridej_popis` | When a line has no `=`, one is synthesised from the ADIF column, so field 11 is never empty. 340 real lines rely on this. |
| loader | Every byte below 32 is dropped, which is how the CRLF-terminated `CountryDel.tab` loads cleanly. |

### Not preserved, deliberately

- **Capacity ceilings.** `popisu_max` is 10000 and the current files already
  need **9056**. Overflowing it in the old engine is not a loud failure: 
  `pridej_popis` (`znacmech.pas:376-381`) sets `ziju := false`, after which
  every lookup returns −1 and *no callsign resolves at all* — silently, since
  `Tchyb1.hlaseni` is commented out in `dDXCC.pas:154`. `TDxccTable` grows
  instead. This is the single most valuable difference.
- **The nil dereference on small tables.** `znacka_najdikam_s`
  (`znacmech.pas:529`) can leave its index one past the last entry, and
  `znacky` is a zero-filled fixed array, so the next read hits nil. Whether it
  triggers depends on whether the data happens to contain a mark sorting above
  the probe key. The real tables survive — `tRobustness` sweeps every
  one- and two-character prefix across all three tables and all three modes to
  prove it — but any small table crashes, which is why `uDxccTestBase` appends
  a `~~~~` sentinel to hand-written fixtures. `TDxccTable` bounds-checks and
  returns "no match".
- **Memory leak on reload.** `Tseznam.done` frees `0..Count-2`, so the last
  mark and description leak on every `ReloadDXCCTables`.

## What the tests establish

224 tests. The suite is written against an interface implemented by both
engines, so the same assertions run twice — once against the original, once
against the replacement.

- **`tCollation`** pins the whole 256-byte mapping byte for byte, plus the
  property everything else rests on: `[ ] % # ?` occupy five consecutive ranks
  (122–126) above every alphanumeric.
- **`tFields`** checks the engine against an independent parser
  (`uRefParser`, written from the file format rather than from the code) over
  **every entry in all three tables** and all twelve fields. This is what makes
  the field-index mapping established rather than assumed.
- **`tPattern`, `tDates`, `tLoading`, `tRobustness`** cover matching,
  time validity, loading and hostile input.
- **`tDifferential`** runs both engines over 93 271 callsigns derived from the
  patterns themselves — every entry reached deliberately, including deleted
  entities that real traffic may not touch for years — plus a systematic sweep
  of short callsign shapes, across eight dates and all three match modes, on
  both `country.tab` variants. It compares the matched pattern and all twelve
  fields, never the index, since the index is an artefact of table order and
  is not what callers read.

  `make diff` last ran exhaustively in **12 min 54 s**, comparing roughly
  **2.9 million lookups** per engine, with **zero disagreements**. The default
  `make test` samples the date/mode matrix so the suite stays around 20 s; the
  sampling is announced on stdout so a partial sweep never reads as a full one.
- **`tSplitting`** does the same for the callsign-splitting layer, against the
  transcription in `uLegacySplitter`. `OnlyArgentineCallsignsDiffer` sweeps
  every Argentine prefix and several foreign ones against every
  single-character suffix and requires that the only disagreements are the
  intended Argentine ones — it does not ignore mismatches in bulk.
- **`tArgentina`** covers the resolved end of the same problem: provinces from
  character 4, the `LU`/`LW` twins, the `[A-O]`/`[P-Z]` splits, named Antarctic
  bases, and a date-scoped exact entry (`=LU1ZBM`, valid only during 2004).

`lotw1.txt`, `eqsl.txt` and `MASTER.SCP` are deliberately **not** used: they
are LoTW/eQSL membership lists and play no part in resolving a callsign.

## Diffing against a real log

`tDifferential` builds its corpus from the tables' own patterns, so it is
exhaustive about the *data* and blind about *traffic*: it can only produce
callsigns the tables already describe, and it stops at the table layer. A real
log contains shapes nothing in `ctyfiles/` anticipated — `4O8/9X0A/P`,
`S5FF-0168`, `03UA`, `OE/OK2PYA/P ` with a trailing space — and it exercises
the callsign-splitting layer, which is where a disagreement would actually
hurt.

`tools/logdiff` runs both engines end to end over a QSO export, following the
same path `dDXCC.id_country` (`dDXCC.pas:688`) takes: split the callsign,
discard the splitter's own `UzNasel`/`ADIF` exactly as `id_country` does, look
the key up in `country_del.tab` and then `country.tab` in prefix mode, and read
the eight fields. Old side is `Tseznam` + the `uLegacySplitter` transcription,
new side is `TDxccTable` + `TDxccResolver`.

```sh
make logdiff CSV=~/export.csv                        # both engines, generated tables
make logdiff CSV=~/export.csv ARGS='--variant plain' # the non-expanded country.tab
make logdiff CSV=~/export.csv ARGS='--tables ~/.config/cqrlog/dxcc_data'
make logdiff CSV=~/export.csv ARGS='--dates boundaries'   # see "The date axis" below
make logdiff-selfcheck                               # prove the tool sees differences
./tools/logdiff --help
```

A single callsign needs no file:

```sh
tools/logdiff --call OK1AYY --date 1992-12-12
tools/logdiff --call OK1AYY --date 1992-12-12 --tables ~/.config/cqrlog/dxcc_data
```

which prints what each engine made of it — the key left after the slashes are
split, the mark that matched, the ADIF, the country, and whether the hit came
from the deleted table. (`OK1AYY` on that date is Czechoslovakia, ADIF 218,
deleted: the search consults `country_del.tab` before `country.tab`, so `OK`
beats `OK[1-7]%`.) `--explain` does the same for every row of a CSV.

Input is CSV with a header and two columns, `qsodate` and `callsign`, as
exported from `cqrlog_main`. Quotes are stripped, `YYYY-MM-DD` becomes
`YYYY/MM/DD`, and rows that needed trimming are counted rather than fixed
silently.

Differences are reported in four classes, most serious first: **dxcc** (the
ADIF number moved — the only one that changes a DXCC standing), **fields**
(same entity, different country string / continent / ITU / WAZ / coordinates),
**key** (same answer, different effective callsign) and **pattern** (same
answer, different mark matched). `--out` writes every differing row with both
keys and both matched patterns, which is what makes a difference diagnosable
rather than merely visible.

`make logdiff-selfcheck` exists because a diff tool that cannot see a
difference is worse than none: it runs a synthetic 22-row fixture that must
produce exactly one `dxcc` and six `fields` differences, and fails the build if
it does not.

### The date axis, and why the log alone is not enough

A log covers the dates its owner was on the air. That is a narrow slice of the
problem: entities appeared and vanished for decades before any given operator
was licensed, and the tables carry **2277 distinct validity boundaries reaching
back to 1939**. For a log starting in 1998, **789 of them** — a third — lie
before the first QSO and are never reached by a run over the log's own dates.

The gap is not only in the table layer. Every date-sensitive step in
`CoVyhodnocovat` is a table probe — the whole-string exact match at the top,
the `Copy(prefix,1,2) + '/' + suffix` probe, and the two `ExNoEquals` probes
that decide which side of a slash is the location — and until
`tSplitting.DifferentialSweepAcrossDates` was added, all of them were compared
at a **single** date, `2020/01/01`.

Two things close it:

- `tSplitting.DifferentialSweepAcrossDates` replays the slash matrix at 20
  dates chosen to sit on real transitions (German unification, the dissolution
  of the USSR, Czechoslovakia splitting into OK/OM, Montenegro, South Sudan,
  Kosovo) and at both edges of the format's own window, 1945/01/01 and
  2050/01/01, plus a day outside each.
- `--dates boundaries` takes the log's **distinct** callsigns and replays them
  at every `ValidFrom` and `ValidTo` in both tables **and at the day either
  side of each** — the boundary catches an inclusive/exclusive mistake, the
  neighbours catch the off-by-one that an inclusive test would hide. For the
  current files that is 5516 dates.

`--callsign-step n` samples the callsign list for a quicker pass; the sampling
is printed in the output, so a partial sweep never reads as a full one.

### What it found

**At the log's own dates.** 58 184 (date, callsign) pairs from a real log,
1998–2026, 21 083 distinct callsigns, 2 281 with a slash. Run against all three
table sets a user can have — generated expanded, generated plain, and the
installed `~/.config/cqrlog/dxcc_data` — **zero differences of any class**, in
about 3 s per run. That is a claim about the traffic this operator actually
worked, and about nothing else; see the date axis above for why that is not the
same as a claim about the engines.

<!-- sweep-results:start -->
**Across the date axis.** The same callsigns replayed at every validity
boundary in the tables and at the day either side of each — 5516 dates
reaching back to 1939, a third of them before the log's first QSO:

| run | comparisons | differences |
|---|---:|---:|
| expanded, all 21 082 callsigns × 5516 dates | 116 288 312 | **0** |
| plain, every 5th callsign × 5516 dates | 23 260 972 | **0** |
| installed `~/.config/cqrlog/dxcc_data`, every 5th × 4977 dates | 20 988 009 | **0** |
| expanded, all 1699 slashed callsigns × 5516 dates | 9 366 168 | **0** |

**169 903 461 comparisons, not one disagreement of any class** — matched mark
included, so this is stronger than "the same country came out". Together with
`make diff`'s ~2.9 M lookups over the synthetic corpus, that is the case for
the two engines being interchangeable.
<!-- sweep-results:end -->

Two things worth keeping from the log-date runs:

- The Argentine fix produced no `dxcc` difference at all, because every
  Argentine province shares ADIF 100. It changes the province string, not the
  entity. See the corrected note under "Argentine suffix letters" above.
- 14 callsigns in that log resolve to no country in *either* engine (16 against
  the older installed files, so `A8OK` and `MR5W` are fixed by newer
  `ctyfiles/`). That is a data gap, not an engine difference, and `logdiff`
  reports it separately for exactly that reason.

Not compared, because they are not in this layer: `DXCCRefArray[adif].pref`,
which comes from MySQL, and the US-state override at `dDXCC.pas:727`, which
needs a state column the export does not carry and which the new parser does
not implement yet.

## Threading

`TDxccTable` is immutable once `LoadFromFile` returns, so any number of threads
may call `Find` concurrently. Reloading is not safe in place — build a new
instance and swap the reference.

Worth noting for the integration stage: the legacy `najdis_s2` already uses
only locals, so *lookups* were reentrant. What is not safe is
`ReloadDXCCTables` (`dDXCC.pas:914`), which does `dispose` + `init` with no
lock while `fRbnMonitor.pas:428` and `fDXCluster.pas:1226` read the same tables
from worker threads. The duplication between `dDXCC` and `dDXCluster` is driven
by the separate MySQL connection per thread, not by this engine.

## A note on `uLegacySplitter`

The engine comparison uses symlinks: `legacy/odbec.pas` and
`legacy/znacmech.pas` point at the real files, so the tests can never drift
from what ships.

The splitter cannot work that way. `CoVyhodnocovat` is a method of a
`TDataModule` in a unit that pulls in `Forms`, `Controls` and `LResources`, so
it will not compile without the LCL. `tests/uLegacySplitter.pas` is therefore a
hand transcription, deliberately kept ugly — same structure, same order of
tests, same variable names.

Since the wiring commit that rule is **inverted**. `dDXCC.CoVyhodnocovat` and
`dDXCluster.CoVyhodnocovat` are now one-line delegations to `TDxccResolver`,
so there is no original left to track: `uLegacySplitter.pas` is the last copy
of the old algorithm and **is the "before" side of the comparison**. Freeze it.
It was transcribed from `dDXCC.pas` at commit `561af345f072`, the last revision
that still carried the algorithm. Editing it to follow `dDXCC.pas` would
silently reduce `tSplitting` to comparing the new engine against itself.

## What the wiring changed in CQRLOG

`dDXCC.pas` and `dDXCluster.pas` keep every public signature; no caller outside
those two units was touched, and no data file or packaging path changed —
the parser reads exactly the `dxcc_data/*.tab` files CQRLOG already builds.

Per unit: the `Tseznam` pair became `TabValid`/`TabDeleted`, `chy1` is gone,
the twelve field indices became named `TDxccEntry` fields, `CoVyhodnocovat`
became a delegation to `TDxccResolver`, and `IsException` became a delegation
to `TDxccSuffixRules.IsIgnoredSuffix` (a documented port of it, hard-coded
`QRP`/`QRPP`/`P` and the no-digit-longer-than-three rule included), which
retired `ExceptionArray` in both units.

Three deliberate behaviour changes came with it:

- **Argentine provinces.** The one intended fix, described above. Province
  string only; ADIF never moves.
- **`dDXCluster` catches up with `dDXCC`.** `dDXCluster.pas:560` carried an
  extra `exit` that made the `Copy(prefix,1,2) + '/' + suffix` probe
  unreachable, so `OK2CQR/XE1` resolved differently in the cluster than in the
  log. Both now run the `dDXCC` variant, which is the one under test.
- **Reload actually reloads.** `ReloadDXCCTables` refreshed the tables but not
  the exception list, so a new `Exceptions.tab` only took effect after a
  restart. Both units now rebuild `TDxccSuffixRules` as part of the reload.
  Rebuilding also replaced `dispose` + `init` with build-new-then-swap, which
  is what `TDxccTable`'s immutability asks for and which retires the leak in
  `Tseznam.done`.

`IsAmbiguous` is deliberately **not** delegated: `TDxccSuffixRules.IsAmbiguousPrefix`
is an exact-match test, while `dDXCC.IsAmbiguous` matches a prefix *of* the
callsign and has a second form for slashed calls. `AmbiguousArray` and
`LoadAmbiguousArray` stay as they were.

## Not done yet

- `IsAmbiguous` consumed by the resolver rather than only by `dDXCC`'s callers.
- The US-state override in `id_country` (`dDXCC.pas:727`), which has no
  counterpart here yet. It still works — it operates on the lookup's outputs,
  so it was untouched by the swap.
- The duplication between `dDXCC` and `dDXCluster`. The driver is one MySQL
  connection per thread, not the parser.
