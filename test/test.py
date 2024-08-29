# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

async def reset(dut):
    # Reset
    dut._log.info("Reset")
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1);
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1);
    dut.rst_n.value = 1

@cocotb.test()
async def test_munch(dut):
    '''
    Unfortunately this does not test much, as video and audio generation is
    quite complex. But we do assert a few basic signals at the beginning as a
    basic sanity check.
    '''
    dut._log.info("Start")

    # Set the clock period to 40ns (25MHz)
    # Actual clock is 25.175 (39.722ns) but whatever
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    await reset(dut)

    dut._log.info("Test munch module")

    await ClockCycles(dut.clk, 2)
    # Should be a black pixel at the beginning of scan
    assert dut.uo_out.value == 0b10001000
    # Audio is on; PWM output is 50:50 with no output, so this will be high at
    # the beginning even though two channels are outputting immediately.
    assert dut.uio_out.value == 0b10000000

    await ClockCycles(dut.clk, 3)
    # Pixel should be black now
    assert dut.uo_out.value == 0b10001000

    # Should put us right at the border between front porch and hsync
    await ClockCycles(dut.clk, 640 + 16 - 3)
    assert dut.uo_out.value == 0b00001000

    # border of hsync and back porch
    await ClockCycles(dut.clk, 96)
    assert dut.uo_out.value == 0b10001000

    # and back at the beginning of the next line; green pixel again
    await ClockCycles(dut.clk, 48)
    assert dut.uo_out.value == 0b10001000
