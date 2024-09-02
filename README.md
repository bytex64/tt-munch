![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# Munch

Munch is an audiovisual presentation (a
["demo"](https://en.wikipedia.org/wiki/Demoscene)) for the [Tiny Tapeout
Demoscene competition](https://tinytapeout.com/competitions/demoscene/).
It shows a munching squares animation and some text via [Leo's VGA
PMOD](https://github.com/mole99/tiny-vga), and plays some music via the
[Tiny Tapeout Audio Pmod](https://github.com/MichaelBell/tt-audio-pmod).

For more technical details, [read the documentation for
project](docs/info.md).

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital and analog designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.

## Running on the iCEstick

In addition to the standard Tiny Tapeout OpenLane build, this can also
be built for the Lattice iCEstick. Run `make icestick` to produce
`munch.bin`, which can be programmed onto your iCEstick with `iceprog
munch.bin`.

You will of course need the usual tools - [yosys](https://github.com/YosysHQ/yosys),
[nextpnr](https://github.com/YosysHQ/nextpnr), and [Project
IceStorm](https://github.com/YosysHQ/icestorm). You can get everything
in one convenient package from the [Yosys OSS CAD
Suite](https://github.com/YosysHQ/oss-cad-suite-build).

This _should_ produce a bitstream that is functionally identical to the
ASIC version, and, with the interface noted below, it will follow all
the descriptions from the [main TT documentation](docs/info.md).

### Pin mapping

The Tiny Tapeout interface (`ui_in`, `uo_out`, etc.) are mapped to
pins on the iCEstick with `src/iceshim.v`.

The main PMOD connector (port1, pins 78-91) is configured as `uo_out`.
The two other headers are mapped to `ui_in` (port0, 112-119) and
`uio_out` (port2, 44-62) except for the two lowest pins on port2.
`port2[0]` is the external clock input `clk` and `port2[1]` is the reset
line `rst_n`.

Additionally, `uio_out[6:4]` is mapped to the first three LEDs. It
displays the internal state of the top three bits of the pattern clock.

### External clock

The iCEstick's internal clock is fixed at 12MHz (or at least, if it is
adjustable I didn't bother figuring out how). I used a Pi Pico to
generate a clock to better emulate the Tiny Tapeout dev board hardware.
I have a program in `clockgen` that can do this because I was not sure
if the TT micropython firmware would work on a regular Pico. It outputs
a 25.177MHz clock on GPIO 21 (pin 27). It can also be tuned by
connecting to it via serial and pressing + or - to adjust the clock
divider.

### Running

The demo will start directly after programming/power on, but it needs
the reset line brought low to properly initialize all the registers. It
should be brought low for at least three periods of the input clock.

## Supplemental tests

There are two module tests under `test/` for testing the LFSR and audio
output. The LFSR test `make -f Makefile.lfsr` just ensures that the LFSR
period is the full 11 bits. The audio test (`make -f Makefile.audio`)
doesn't actually test anything. I just use it to inspect the waveforms
with GTKWave.
