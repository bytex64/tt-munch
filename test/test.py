# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    await Timer(5, "us")
    dut.ena.value = 1
    await Timer(5, "us")

    # Reset
    dut._log.info("Reset")
    dut.rst_n.value = 1
    await Timer(5, "us")
    dut.rst_n.value = 0
    await Timer(10, "us")
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    await ClockCycles(dut.clk, 20)

    assert dut.uo_out.value == 3
