`default_nettype none
`timescale 1ns / 1ps

module tb_lfsr ();

  // Dump the signals to a VCD file. You can view it with gtkwave.
  initial begin
    $dumpfile("tb_lfsr.vcd");
    $dumpvars(0, tb_lfsr);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  wire [5:0] bits;
  wire [10:0] lfsr_bits;

  lfsr lfsr_dev(
    .clk(clk),
    .rst_n(rst_n),
    .bits(bits)
  );

  assign lfsr_bits = lfsr_dev.lfsr;

endmodule
