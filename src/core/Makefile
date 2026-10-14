# Test suite for LCL-free units extracted from forms and data modules (SCP search, ...).
#
# Same idea as src/rbn and src/dxcc-parser: the units under test need neither LCL
# nor MySQL, so the suite is built with plain fpc and runs anywhere FPC is
# installed.  Compiled units go to lib/, the binary to tests/coretests.

FPC        ?= fpc
# -WM is a Darwin-only flag; passing it on Linux aborts fpc before it compiles
# a single line.
UNAME_S    := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
MACFLAGS    = -WM11.0
endif
FPCFLAGS   ?= -O1 -vw $(MACFLAGS)
# synapse for synaser (TBlockSerial) used by the WinKeyer driver
UNITPATHS   = -Fu. -Futests -Fu../synapse
OUTPUT      = -FUlib -FEtests
BIN         = tests/coretests
SOURCES     = $(wildcard *.pas) $(wildcard tests/*.pas) tests/coretests.lpr

.PHONY: all test clean

all: $(BIN)

$(BIN): $(SOURCES)
	@mkdir -p lib
	$(FPC) $(FPCFLAGS) $(UNITPATHS) $(OUTPUT) -o$(BIN) tests/coretests.lpr

test: $(BIN)
	./$(BIN) --format=plain --all

clean:
	rm -rf lib $(BIN)
