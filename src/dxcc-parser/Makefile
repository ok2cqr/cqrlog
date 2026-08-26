# Test suite for the DXCC parser.
#
# Deliberately uses plain fpc, not lazbuild: the units under test need neither
# LCL nor MySQL, so the suite builds and runs anywhere FPC is installed.
#
# Nothing here writes into src/.  Compiled units go to lib/, the binary to
# tests/dxcctests, generated fixtures to tests/data/generated/.

FPC        ?= fpc
# -WM is a Darwin-only flag; passing it on Linux aborts fpc before it compiles
# a single line.
UNAME_S    := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
MACFLAGS    = -WM11.0
endif
FPCFLAGS   ?= -dnuse_ddata -O1 -vw $(MACFLAGS)
UNITPATHS   = -Fu. -Fulegacy -Futests
OUTPUT      = -FUlib -FEtests
BIN         = tests/dxcctests
LOGDIFF    = tools/logdiff
BENCH      = tools/bench
SELFCHECK   = tests/data/logdiff-selfcheck.csv
DATA        = tests/data/generated/country-plain.tab
SOURCES     = $(wildcard *.pas) $(wildcard tests/*.pas) tests/dxcctests.lpr

.PHONY: all test test-full diff data logdiff logdiff-selfcheck bench clean distclean help

all: $(BIN)

$(BIN): $(SOURCES) | $(DATA)
	@mkdir -p lib
	$(FPC) $(FPCFLAGS) $(UNITPATHS) $(OUTPUT) -o$(BIN) tests/dxcctests.lpr

# The generated tables mirror what CQRLOG builds at runtime; see the script.
$(DATA):
	tools/mkdxccdata.sh

data:
	tools/mkdxccdata.sh

test: $(BIN)
	./$(BIN) --format=plain --all

# Same suite, but the old-vs-new comparison walks every callsign in the corpus
# at every date and every match mode instead of sampling the matrix.  Slower;
# this is the one to run before believing the two engines are interchangeable.
test-full: $(BIN)
	DXCC_DIFF_FULL=1 ./$(BIN) --format=plain --all

# Just the old-vs-new comparison, exhaustively.
diff: $(BIN)
	DXCC_DIFF_FULL=1 ./$(BIN) --format=plain --suite=TDifferentialTests

# --- real-log comparison ----------------------------------------------------
#
# The differential test derives its corpus from the tables' own patterns, so it
# never sees a callsign the data did not anticipate.  logdiff runs both engines
# over an actual QSO export instead -- splitter included, exactly the path
# dDXCC.id_country takes.  See ./tools/logdiff --help.
$(LOGDIFF): tools/logdiff.lpr $(SOURCES) | $(DATA)
	@mkdir -p lib
	$(FPC) $(FPCFLAGS) $(UNITPATHS) -FUlib -FEtools -o$(LOGDIFF) tools/logdiff.lpr

# make logdiff CSV=~/export.csv [ARGS='--variant plain --out /tmp/diff.csv']
logdiff: $(LOGDIFF)
	@test -n "$(CSV)" || { \
	  echo "usage: make logdiff CSV=/path/to/export.csv [ARGS='...']"; exit 2; }
	./$(LOGDIFF) --csv "$(CSV)" $(ARGS)

# --- speed ------------------------------------------------------------------
#
# Same two engines, same id_country path, timed instead of compared.  Built
# with -O2 because that is what cqrlog.lpi uses; the -O1 of the test suite
# would measure code the application never runs.
#
# make bench [ADIF='~/a.adi ~/b.adi'] [ARGS='--rounds 10']
$(BENCH): tools/bench.lpr $(SOURCES) | $(DATA)
	@mkdir -p lib/bench
	$(FPC) -dnuse_ddata -O2 -vw $(MACFLAGS) $(UNITPATHS) -FUlib/bench -FEtools -o$(BENCH) tools/bench.lpr

bench: $(BENCH)
	./$(BENCH) $(foreach f,$(ADIF),--adif $(f)) $(ARGS)

# A diff tool that cannot see a difference is worse than none, so prove it can.
# The fixture is synthetic.  Six rows where the Argentine fix sharpens the
# province without moving the DXCC entity, one where a three-character prefix
# does move it (LU1/Z -> Antarctica, which the original could not reach because
# it wrote character 4 of a three-character string), and the rest unchanged.
logdiff-selfcheck: $(LOGDIFF)
	@out=$$(./$(LOGDIFF) --csv $(SELFCHECK) --keys) || { echo "$$out"; exit 1; }; \
	echo "$$out"; \
	echo "$$out" | grep -q 'SUMMARY rows=22 dxcc=1 fields=6 key=0 pattern=0' || { \
	  echo; echo "logdiff-selfcheck: FAILED"; \
	  echo "  expected: SUMMARY rows=22 dxcc=1 fields=6 key=0 pattern=0"; exit 1; }; \
	echo; echo "logdiff-selfcheck: OK"

# Removes build output only; keeps the generated fixtures, which are slow to
# rebuild and never change unless ctyfiles/ does.
clean:
	rm -rf lib
	rm -f $(BIN) $(LOGDIFF) $(BENCH)

distclean: clean
	rm -rf tests/data/generated

help:
	@echo "make            build the test runner"
	@echo "make test       build and run the whole suite (matrix sampled)"
	@echo "make test-full  the whole suite, old-vs-new comparison exhaustive"
	@echo "make diff       only the old-vs-new comparison, exhaustive"
	@echo "make data       regenerate fixtures from ../../ctyfiles"
	@echo "make logdiff CSV=<file>   run both engines over a real QSO export"
	@echo "make logdiff-selfcheck    prove logdiff can actually see a difference"
	@echo "make bench [ADIF=<files>]  time both engines over the same callsigns"
	@echo "make clean      remove build output"
	@echo "make distclean  also remove generated fixtures"
