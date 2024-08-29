`default_nettype none
`timescale 1ns / 1ps

module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  tt_um_bytex64_munch munch(
    .clk(clk),
    .rst_n(rst_n),
    .ena(1'b1),
    .ui_in(8'b0),
    .uo_out(uo_out),
    .uio_in(8'b0),
    .uio_out(uio_out),
    .uio_oe(uio_oe)
  );

endmodule
