SOURCES = hvsync_generator.v audio.v video.v project.v

PSOURCES = $(addprefix src/,$(SOURCES))

.PHONY: check
check:
	yosys -p 'read -vlog2k $(PSOURCES); check'

.PHONY: lint
lint:
	verilator --lint-only -Wall -Wno-DECLFILENAME $(PSOURCES)

munch.vvp: $(PSOURCES)
	iverilog -v -o $@ $(PSOURCES)

.PHONY: icestick
icestick: munch.bin

munch.bin: $(PSOURCES) src/iceshim.v
	yosys icestick.ys
	nextpnr-ice40 --hx1k --package tq144 --json munch.json --pcf icestick.pcf --asc munch.asc --freq 25.175
	icepack munch.asc $@
