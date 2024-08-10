/*
 * Copyright (c) 2024 Chip Black
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_bytex64_munch (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire [9:0] hpos;
  wire [9:0] vpos;
  wire hsync, vsync;
  wire display_on;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;

  assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
  assign uio_out = 0;
  assign uio_oe  = 0;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(display_on),
    .hpos(hpos),
    .vpos(hpos)
  );

  assign R = display_on ? hpos[3:2] : 2'b00;
  assign G = display_on ? hpos[3:2] : 2'b00;
  assign B = display_on ? hpos[3:2] : 2'b00;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule
