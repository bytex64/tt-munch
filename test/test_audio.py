# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

async def reset(dut):
    # Reset
    dut._log.info("Reset")
    dut.rst_n.value = 1
    await ClockCycles(dut.vsync, 1);
    dut.rst_n.value = 0
    await ClockCycles(dut.vsync, 1);
    dut.rst_n.value = 1

@cocotb.test()
async def test_audio_clock(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.vsync, 16, units="ms")
    cocotb.start_soon(clock.start())

    await reset(dut)

    dut._log.info("Test Audio Clock")
    await ClockCycles(dut.clock_gen.audio_tick, 1024)
