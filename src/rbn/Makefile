# Test suite for the RBN receive path (line framer, spot parser).
#
# Same idea as src/dxcc-parser: the units under test need neither LCL nor MySQL,
# so the suite is built with plain fpc and runs anywhere FPC is installed.
# Compiled units go to lib/, the binary to tests/rbntests.  The fixtures are
# real traffic recorded by tools/rbn-capture, with the callsign suffixes scrambled.

FPC        ?= fpc
# -WM is a Darwin-only flag; passing it on Linux aborts fpc before it compiles
# a single line.
UNAME_S    := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
MACFLAGS    = -WM11.0
endif
FPCFLAGS   ?= -O1 -vw $(MACFLAGS)
UNITPATHS   = -Fu. -Futests
OUTPUT      = -FUlib -FEtests
BIN         = tests/rbntests
SOURCES     = $(wildcard *.pas) $(wildcard tests/*.pas) tests/rbntests.lpr

.PHONY: all test clean

all: $(BIN)

$(BIN): $(SOURCES)
	@mkdir -p lib
	$(FPC) $(FPCFLAGS) $(UNITPATHS) $(OUTPUT) -o$(BIN) tests/rbntests.lpr

test: $(BIN)
	./$(BIN) --format=plain --all

clean:
	rm -rf lib $(BIN)
