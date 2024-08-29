/*
 * Copyright (c) 2024 Chip Black
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module clock_generator(
  input wire clk,                  // 25.175MHz main clock
  input wire rst_n,                // active low reset
  output wire [5:0] pwm_clock,     // 393kHz PWM clock (main / 64)
  input wire vsync,                // ~60Hz video clock
  output wire [1:0] atick_clock,   // audio tick clock state, used for volume modulation
  output wire [3:0] pattern_clock  // pattern clock, increments with audio_tick
);
  reg [5:0] r_pwm_clock;
  reg [2:0] r_atick_clock;
  reg [3:0] r_pattern_clock;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      r_pwm_clock <= 0;
    else
      r_pwm_clock <= r_pwm_clock + 1;
  end
  
  assign pwm_clock = r_pwm_clock;

  always @(posedge vsync, negedge rst_n) begin
    if (!rst_n)
      r_atick_clock <= 0;
    else begin
      // Divide vsync by 6 to get 10Hz sequencer clock
      // 10Hz = 600 ticks per minute
      // four ticks per beat
      // 150 BPM
      if (r_atick_clock == 5)
        r_atick_clock <= 0;
      else
        r_atick_clock <= r_atick_clock + 1;
    end
  end

  assign atick_clock = r_atick_clock[2:1];
  wire audio_tick = (r_atick_clock == 0);

  always @(posedge audio_tick, negedge rst_n) begin
    if (!rst_n)
      r_pattern_clock <= 0;
    else
      r_pattern_clock <= r_pattern_clock + 1;
  end

  assign pattern_clock = r_pattern_clock;

endmodule

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

  // Video timing/output signals
  wire [9:0] hpos;
  wire [9:0] vpos;
  wire hsync, vsync;
  wire display_on;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;

  // Video generation signals
  wire [5:0] layer [1:0];
  wire [5:0] pixel_color;
  wire [2:0] dither;
  wire [1:0] bright [7:0];  // 8 2-bit brightness levels
  wire [5:0] palette [7:0]; // 8 6-bit colors
  wire [2:0] munch_level;   // brightness output for munch module
  wire text_pixel;          // on/off output for text module

  // Audio signals
  wire audio;               // Audio output (~200kHz PWM)
  wire [5:0] pwm_clock;
  wire [1:0] atick_clock;
  wire [3:0] pattern_clock;

  // Misc signals
  wire [5:0] lfsr;
  wire [1:0] stage;

  // State
  reg [6:0] counter;        // general 7-bit counter

  clock_generator clock_gen(
    .clk(clk),
    .rst_n(rst_n),
    .pwm_clock(pwm_clock),
    .vsync(vsync),
    .atick_clock(atick_clock),
    .pattern_clock(pattern_clock)
  );

  lfsr lfsr_dev(
    .clk(clk),
    .rst_n(rst_n),
    .bits(lfsr)
  );

  audio audio_mod(
    .pwm_clock(pwm_clock),
    .atick_clock(atick_clock),
    .pattern_clock(pattern_clock),
    .rst_n(rst_n),
    .rng(lfsr[0]),
    .audio(audio)
  );

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(!rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(display_on),
    .hpos(hpos),
    .vpos(vpos)
  );

  assign palette[0] = 6'b000000;
  assign palette[1] = 6'b110000;
  assign palette[2] = 6'b001100;
  assign palette[3] = 6'b000011;
  assign palette[4] = 6'b001111;
  assign palette[5] = 6'b110011;
  assign palette[6] = 6'b111100;
  assign palette[7] = 6'b111111;

  assign dither[0] = lfsr[4] & lfsr[5]; // 1/4
  assign dither[1] = lfsr[3];           // 1/2
  assign dither[2] = lfsr[1] | lfsr[2]; // 3/4
/*
  assign dither[0] = hpos[0] & vpos[0];
  assign dither[1] = hpos[0] ^ vpos[0];
  assign dither[2] = hpos[0] | vpos[0];
*/

  assign bright[0] = 2'b00;
  assign bright[1] = {1'b0, dither[0]};
  assign bright[2] = {1'b0, dither[1]};
  assign bright[3] = {1'b0, dither[2]};
  assign bright[4] = 2'b01;
  assign bright[5] = {dither[0], dither[2]};
  assign bright[6] = 2'b10;
  assign bright[7] = 2'b11;

  munch munch_gen(
    .counter(counter),
    .hpos(hpos[8:2]),
    .vpos(vpos[8:2]),
    .level(munch_level)
  );

  text_sequencer text_gen(
    .selector(pattern_clock[3:2]),
    .hpos(hpos),
    .vpos(vpos),
    .pixel(text_pixel)
  );

  stage_sequencer stage_seq_inst(
    .seq_clk(!pattern_clock[3]),
    .rst_n(rst_n),
    .stage(stage)
  );

  wire [2:0] munch_color = {1'b0, stage}; //stage == 0 ? 0 : (stage == 1 ? 2 : lfsr[2:0]);

  assign layer[0] = palette[munch_color] & {3{bright[munch_level]}};
  // color bars
  //assign layer[0] = palette[vpos[6:4]] & {3{bright[hpos[6:4]]}};
  assign layer[1] = text_pixel ? palette[7] : 0;

  assign pixel_color = layer[1] != 0 ? layer[1] : layer[0];

  always @(posedge vsync, negedge rst_n) begin
    if (!rst_n)
      counter <= 0;
    else
      counter <= counter + 1;
  end

  assign R = display_on ? pixel_color[5:4] : 2'b00;
  assign G = display_on ? pixel_color[3:2] : 2'b00;
  assign B = display_on ? pixel_color[1:0] : 2'b00;

  assign uo_out  = {!hsync, B[0], G[0], R[0], !vsync, B[1], G[1], R[1]};
  assign uio_out = {audio, pattern_clock[3:1], 4'b0};
  assign uio_oe  = 8'b11110000;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in, uio_in, 1'b0};
endmodule

module lfsr(
  input wire clk,
  input wire rst_n,
  output wire [5:0] bits
);
  reg [10:0] lfsr;          // LFSR

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      lfsr <= 11'h0;
    else
      lfsr <= {lfsr[0] ~^ lfsr[2], lfsr[10:1]};
  end

  assign bits = lfsr[5:0];
endmodule

module stage_sequencer(
  input wire seq_clk,
  input wire rst_n,
  output wire [1:0] stage
);
  reg [3:0] timer;
  reg [1:0] stage_seq;

  wire [3:0] stage_timings [3:0];

  assign stage_timings[0] = 3;
  assign stage_timings[1] = 7;
  assign stage_timings[2] = 7;
  assign stage_timings[3] = 0;

  always @(posedge seq_clk, negedge rst_n) begin
    if (!rst_n) begin
      stage_seq <= 0;
      timer <= stage_timings[0];
    end
    else begin
      if (stage_timings[stage_seq] != 0) begin
        if (timer == 0) begin
          stage_seq <= stage_seq + 1;
          timer <= stage_timings[stage_seq + 1];
        end
        else
          timer <= timer - 1;
      end
    end
  end

  assign stage = stage_seq;

endmodule
