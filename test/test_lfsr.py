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
async def test_lfsr(dut):
    dut._log.info("Start")

    # Set the clock period to 40ns (25MHz)
    # Actual clock is 25.175 (39.722ns) but whatever
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    await reset(dut)

    dut._log.info("Test LFSR module")

    await ClockCycles(dut.clk, 1)

    for i in range(1, 2**11 - 1):
        await ClockCycles(dut.clk, 1)
        assert dut.lfsr_bits.value != 0

    await ClockCycles(dut.clk, 1)
    assert dut.lfsr_bits.value == 0
