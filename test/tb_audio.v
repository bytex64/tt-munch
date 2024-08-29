module tb_audio ();
  initial begin
    $dumpfile("tb_audio.vcd");
    $dumpvars(0, tb_audio);
    #1;
  end

  reg vsync;
  reg rst_n;
  wire [5:0] pwm_clock;
  wire [1:0] atick_clock;
  wire [3:0] pattern_clock;

  clock_generator clock_gen(
    .clk(0),
    .rst_n(rst_n),
    .pwm_clock(pwm_clock),
    .vsync(vsync),
    .atick_clock(atick_clock),
    .pattern_clock(pattern_clock)
  );

  wire [11:0] freq0, freq1, freq2, freq3;
  wire [1:0] vol0, vol1, vol2, vol3;

  sequencer seq(
    .tick_clock(atick_clock),
    .pattern_clock(pattern_clock),
    .rst_n(rst_n),
    .freq0(freq0),
    .freq1(freq1),
    .freq2(freq2),
    .freq3(freq3),
    .vol0(vol0),
    .vol1(vol1),
    .vol2(vol2),
    .vol3(vol3)
  );

  wire [2:0] stage;

  stage_sequencer stage_seq_inst(
    .seq_clk(!pattern_clock[3]),
    .rst_n(rst_n),
    .stage(stage)
  );

endmodule
