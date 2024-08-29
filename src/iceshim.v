/* This adapts the icestick I/O to work with the project module */

`default_nettype none

module iceshim(
  input wire [7:0] port0,
  output wire [7:0] port1,
  inout wire [7:0] port2, // the 0th bit is stolen by rst, 1st bit is external clock
  output wire [4:0] leds,
  input wire clk
);

  wire [7:0] uio_in;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  //assign port2[0] = uio_oe[0] ? uio_out[0] : 1'bZ;
  //assign port2[1] = uio_oe[1] ? uio_out[1] : 1'bZ;
  assign port2[2] = uio_oe[2] ? uio_out[2] : 1'bZ;
  assign port2[3] = uio_oe[3] ? uio_out[3] : 1'bZ;
  assign port2[4] = uio_oe[4] ? uio_out[4] : 1'bZ;
  assign port2[5] = uio_oe[5] ? uio_out[5] : 1'bZ;
  assign port2[6] = uio_oe[6] ? uio_out[6] : 1'bZ;
  assign port2[7] = uio_oe[7] ? uio_out[7] : 1'bZ;
  //assign uio_in[0] = port2[0];
  //assign uio_in[1] = port2[1];
  assign uio_in[2] = port2[2];
  assign uio_in[3] = port2[3];
  assign uio_in[4] = port2[4];
  assign uio_in[5] = port2[5];
  assign uio_in[6] = port2[6];
  assign uio_in[7] = port2[7];
  assign leds[2:0] = uio_out[6:4];

  tt_um_bytex64_munch user_module(
    .ui_in(port0),
    .uo_out(port1),
    .uio_in(uio_in),
    .uio_out(uio_out),
    .uio_oe(uio_oe),
    .ena(1),
    .clk(port2[1]),
    .rst_n(port2[0])
  );
endmodule
