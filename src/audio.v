module audio(
  input wire [5:0] pwm_clock,
  input wire [1:0] atick_clock,
  input wire [3:0] pattern_clock,
  input wire rst_n,
  input wire rng,
  output wire audio
);
  wire [11:0] audio_time0;  // per-channel oscillator timer values
  wire [11:0] audio_time1;
  wire [11:0] audio_time2;
  wire [11:0] audio_time3;
  wire [1:0] audio_vol0;    // per-channel volume values
  wire [1:0] audio_vol1;
  wire [1:0] audio_vol2;
  wire [1:0] audio_vol3;

  sequencer seq(
    .tick_clock(atick_clock[1:0]),
    .pattern_clock(pattern_clock),
    .rst_n(rst_n),
    .freq0(audio_time0),
    .freq1(audio_time1),
    .freq2(audio_time2),
    .freq3(audio_time3),
    .vol0(audio_vol0),
    .vol1(audio_vol1),
    .vol2(audio_vol2),
    .vol3(audio_vol3)
  );

  audio_psg audio_gen(
    .pwm_clock(pwm_clock),
    .rst_n(rst_n),
    .timer0(audio_time0),
    .timer1(audio_time1),
    .timer2(audio_time2),
    .timer3(audio_time3),
    .vol0(audio_vol0),
    .vol1(audio_vol1),
    .vol2(audio_vol2),
    .vol3(audio_vol3),
    .rng(rng),
    .audio(audio)
  );

endmodule

/* PSG with three square wave channels and one noise channel
 * 2-bit volume per channel
 */
module audio_psg(
  input wire [5:0] pwm_clock,
  input wire rst_n,
  input wire [11:0] timer0,
  input wire [11:0] timer1,
  input wire [11:0] timer2,
  input wire [11:0] timer3,
  input wire [1:0] vol0,
  input wire [1:0] vol1,
  input wire [1:0] vol2,
  input wire [1:0] vol3,
  input wire rng,
  output wire audio
);

  wire [5:0] level;
  wire f_clock;
  wire ch0_state, ch1_state, ch2_state, ch3_state;

  assign f_clock = (pwm_clock == 0);

  audio_psg_square_gen chan0(
    .clk(f_clock),
    .rst_n(rst_n),
    .timer(timer0),
    .out(ch0_state)
  );
  audio_psg_square_gen chan1(
    .clk(f_clock),
    .rst_n(rst_n),
    .timer(timer1),
    .out(ch1_state)
  );
  audio_psg_square_gen chan2(
    .clk(f_clock),
    .rst_n(rst_n),
    .timer(timer2),
    .out(ch2_state)
  );
  audio_psg_noise_gen chan3(
    .clk(f_clock),
    .rst_n(rst_n),
    .timer(timer3),
    .rng(rng),
    .out(ch3_state)
  );

  // There's probably a better way to do this.
  assign level = 31 + {(ch0_state ? {3'b0, vol0} : -{3'b0, vol0}), rng}
                    + {(ch1_state ? {3'b0, vol1} : -{3'b0, vol1}), rng}
                    + {(ch2_state ? {3'b0, vol2} : -{3'b0, vol2}), rng}
                    + {(ch3_state ? {3'b0, vol3} : -{3'b0, vol3}), rng};
  assign audio = pwm_clock <= level;
endmodule

/* Signal generator for noise channel */
module audio_psg_noise_gen(
  input wire clk,           // the audio clock, which is the main clock
                            // divided by 64.
  input wire rst_n,
  input wire [11:0] timer,  // the timer value
  input wire rng,           // random bit from lfsr
  output wire out           // the square wave output
);

  reg [11:0] ch_counter;
  reg ch_state;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      ch_counter <= 0;
      ch_state <= 0;
    end
    else begin
      if (ch_counter == timer) begin
        ch_state <= rng;
        ch_counter <= 0;
      end
      else
        ch_counter <= ch_counter + 1;
    end
  end

  assign out = ch_state;

endmodule

/* Signal generator for square wave channel */
module audio_psg_square_gen(
  input wire clk,           // the audio clock, which is the main clock
                            // divided by 64.
  input wire rst_n,
  input wire [11:0] timer,  // the timer value
  output wire out           // the square wave output
);

  reg [11:0] ch_counter;
  reg ch_state;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      ch_counter <= 0;
      ch_state <= 0;
    end
    else begin
      if (ch_counter == timer) begin
        ch_state <= !ch_state;
        ch_counter <= 0;
      end
      else
        ch_counter <= ch_counter + 1;
    end
  end

  assign out = ch_state;

endmodule

parameter T_Fs1 = 12'd2126; // 185    Hz
parameter T_Gs1 = 12'd1894; // 207.65 Hz
parameter T_A1  = 12'd1788; // 220    Hz
parameter T_As1 = 12'd1688; // 233.08 Hz
parameter T_B1  = 12'd1593; // 246.94 Hz
parameter T_C2  = 12'd1503; // 261.63 Hz
parameter T_Fs2 = 12'd1063; // 370    Hz
parameter T_Gs2 = 12'd947;  // 415.3  Hz
parameter T_As2 = 12'd844;  // 466.16 Hz
parameter T_B2  = 12'd796;  // 493.88 Hz
parameter T_C3  = 12'd752;  // 523.25 Hz
parameter T_C4  = 12'd376;  // 1046.5 Hz
parameter T_B7  = 12'd100;  // 3951   Hz

parameter N_Fs1 = 1;
parameter N_Gs1 = 2;
parameter N_A1  = 3;
parameter N_As1 = 4;
parameter N_B1  = 5;
parameter N_C2  = 6;
parameter N_Fs2 = 7;
parameter N_Gs2 = 8;
parameter N_As2 = 9;
parameter N_B2  = 10;
parameter N_C3  = 11;
parameter N_C4  = 12;
parameter N_B7  = 13;

module note_map(
  input wire [3:0] select,
  output wire [11:0] freq
);
  wire [11:0] notes [13:0];

  assign notes[0]     = 0;
  assign notes[N_Fs1] = T_Fs1;
  assign notes[N_Gs1] = T_Gs1;
  assign notes[N_A1]  = T_A1;
  assign notes[N_As1] = T_As1;
  assign notes[N_B1]  = T_B1;
  assign notes[N_C2]  = T_C2;
  assign notes[N_Fs2] = T_Fs2;
  assign notes[N_Gs2] = T_Gs2;
  assign notes[N_As2] = T_As2;
  assign notes[N_B2]  = T_B2;
  assign notes[N_C3]  = T_C3;
  assign notes[N_C4]  = T_C4;
  assign notes[N_B7]  = T_B7;

  assign freq = notes[select];
endmodule

// Turn this off for the pattern section, since they all have the same
// interface but they're not all using the select lines.
// verilator lint_off UNUSEDSIGNAL

module pattern1_1(
  input wire [3:0] select,
  output wire [3:0] note
);
  wire [3:0] note_sequence [15:0];

  assign note_sequence[0]  = N_C2;
  assign note_sequence[1]  = 0;
  assign note_sequence[2]  = 0;
  assign note_sequence[3]  = N_C2;
  assign note_sequence[4]  = 0;
  assign note_sequence[5]  = 0;
  assign note_sequence[6]  = N_C2;
  assign note_sequence[7]  = 0;
  assign note_sequence[8]  = 0;
  assign note_sequence[9]  = 0;
  assign note_sequence[10] = N_As1;
  assign note_sequence[11] = 0;
  assign note_sequence[12] = N_As1;
  assign note_sequence[13] = 0;
  assign note_sequence[14] = N_As1;
  assign note_sequence[15] = N_C2;

  assign note = note_sequence[select];
endmodule

module pattern1_2(
  input wire [3:0] select,
  output wire [3:0] note
);
  wire [3:0] note_sequence [15:0];

  assign note_sequence[0]  = N_Gs1;
  assign note_sequence[1]  = 0;
  assign note_sequence[2]  = 0;
  assign note_sequence[3]  = N_Gs1;
  assign note_sequence[4]  = 0;
  assign note_sequence[5]  = 0;
  assign note_sequence[6]  = N_Gs1;
  assign note_sequence[7]  = 0;
  assign note_sequence[8]  = 0;
  assign note_sequence[9]  = 0;
  assign note_sequence[10] = N_Fs1;
  assign note_sequence[11] = 0;
  assign note_sequence[12] = N_Fs1;
  assign note_sequence[13] = 0;
  assign note_sequence[14] = N_Fs1;
  assign note_sequence[15] = N_Gs1;

  assign note = note_sequence[select];
endmodule

module pattern1_3(
  input wire [3:0] select,
  output wire [3:0] note
);
  wire [3:0] note_sequence [15:0];

  assign note_sequence[0]  = N_Gs1;
  assign note_sequence[1]  = 0;
  assign note_sequence[2]  = 0;
  assign note_sequence[3]  = N_Gs1;
  assign note_sequence[4]  = 0;
  assign note_sequence[5]  = 0;
  assign note_sequence[6]  = N_Gs1;
  assign note_sequence[7]  = 0;
  assign note_sequence[8]  = N_As1;
  assign note_sequence[9]  = 0;
  assign note_sequence[10] = 0;
  assign note_sequence[11] = N_As1;
  assign note_sequence[12] = 0;
  assign note_sequence[13] = 0;
  assign note_sequence[14] = N_B1;
  assign note_sequence[15] = 0;

  assign note = note_sequence[select];
endmodule

// Where is pattern2? It used to be a lower octave version of pattern1 but that
// is now handled by bit shifting.

module pattern3_1(
  input wire [3:0] select,
  output wire [3:0] note
);
  assign note = N_C2;
endmodule

module pattern3_2(
  input wire [3:0] select,
  output wire [3:0] note
);
  wire [3:0] note_sequence [15:0];

  assign note_sequence[0] = N_C2;
  assign note_sequence[1] = N_C2;
  assign note_sequence[2] = N_C2;
  assign note_sequence[3] = N_C2;
  assign note_sequence[4] = N_C2;
  assign note_sequence[5] = N_C2;
  assign note_sequence[6] = N_C2;
  assign note_sequence[7] = N_C2;
  assign note_sequence[8] = N_C2;
  assign note_sequence[9] = N_C2;
  assign note_sequence[10] = N_C2;
  assign note_sequence[11] = N_As1;
  assign note_sequence[12] = N_As1;
  assign note_sequence[13] = N_As1;
  assign note_sequence[14] = N_A1;
  assign note_sequence[15] = N_Gs1;

  assign note = note_sequence[select];
endmodule

module pattern3_3(
  input wire [3:0] select,
  output wire [3:0] note
);
  assign note = select <= 10 ? N_Gs1 : N_Fs1;
endmodule

module pattern3_4(
  input wire [3:0] select,
  output wire [3:0] note
);
  wire [3:0] note_sequence [15:0];

  assign note_sequence[0]  = N_Gs1;
  assign note_sequence[1]  = N_Gs1; 
  assign note_sequence[2]  = N_Gs1;
  assign note_sequence[3]  = N_Gs1;
  assign note_sequence[4]  = N_Gs1;
  assign note_sequence[5]  = N_Gs1;
  assign note_sequence[6]  = N_Fs1;
  assign note_sequence[7]  = N_Fs1;
  assign note_sequence[8]  = N_Gs1;
  assign note_sequence[9]  = N_Gs1;
  assign note_sequence[10] = N_Gs1;
  assign note_sequence[11] = N_Fs1;
  assign note_sequence[12] = N_Gs1;
  assign note_sequence[13] = N_Gs1;
  assign note_sequence[14] = N_As1;
  assign note_sequence[15] = N_As1;

  assign note = note_sequence[select];
endmodule

module pattern4_1(
  input wire [3:0] select,
  output wire [3:0] note
);
  assign note = select[1:0] == 0 ? N_C4 : 0;
endmodule

module pattern4_2(
  input wire [3:0] select,
  output wire [3:0] note
);
  assign note = select[1:0] == 0 ? N_C4 : (select[1:0] == 2 ? N_B7 : 0);
endmodule

// verilator lint_on UNUSEDSIGNAL

module pattern_selector(
  input wire [3:0] pattern,
  input wire [3:0] row,
  output wire [11:0] freq
);

  wire [3:0] pnotes [15:0];

  // Pattern 0 is empty
  assign pnotes[0] = 0;

  pattern1_1 p1(
    .select(row),
    .note(pnotes[1])
  );

  pattern1_2 p2(
    .select(row),
    .note(pnotes[2])
  );

  pattern1_3 p3(
    .select(row),
    .note(pnotes[3])
  );

  pattern3_1 p4(
    .select(row),
    .note(pnotes[4])
  );

  pattern3_2 p5(
    .select(row),
    .note(pnotes[5])
  );

  pattern3_3 p6(
    .select(row),
    .note(pnotes[6])
  );

  pattern3_4 p7(
    .select(row),
    .note(pnotes[7])
  );

  pattern4_1 p8(
    .select(row),
    .note(pnotes[8])
  );

  pattern4_2 p9(
    .select(row),
    .note(pnotes[9])
  );

  // All other patterns are unassigned
  assign pnotes[10] = 0;
  assign pnotes[11] = 0;
  assign pnotes[12] = 0;
  assign pnotes[13] = 0;
  assign pnotes[14] = 0;
  assign pnotes[15] = 0;

  note_map nm1(
    .select(pnotes[pattern]),
    .freq(freq)
  );

endmodule

module instrument0(
  input wire [1:0] select,
  output wire [1:0] vol
);

  wire [1:0] vol_sequence [3:0];

  assign vol_sequence[0] = 2'b11;
  assign vol_sequence[1] = 2'b11;
  assign vol_sequence[2] = 2'b11;
  assign vol_sequence[3] = 2'b00;

  assign vol = vol_sequence[select];

endmodule

module instrument1(
  input wire [1:0] select,
  output wire [1:0] vol
);

  wire [1:0] vol_sequence [3:0];

  assign vol_sequence[0] = 2'b10;
  assign vol_sequence[1] = 2'b10;
  assign vol_sequence[2] = 2'b01;
  assign vol_sequence[3] = 2'b00;

  assign vol = vol_sequence[select];

endmodule

module instrument2(
  input wire [1:0] select,
  output wire [1:0] vol
);

  wire [1:0] vol_sequence [3:0];

  assign vol_sequence[0] = 2'b11;
  assign vol_sequence[1] = 2'b01;
  assign vol_sequence[2] = 2'b00;
  assign vol_sequence[3] = 2'b00;

  assign vol = vol_sequence[select];

endmodule

module sequencer(
  input wire [1:0] tick_clock,
  input wire [3:0] pattern_clock,
  input wire rst_n,
  output wire [11:0] freq0,
  output wire [11:0] freq1,
  output wire [11:0] freq2,
  output wire [11:0] freq3,
  output wire [1:0] vol0,
  output wire [1:0] vol1,
  output wire [1:0] vol2,
  output wire [1:0] vol3
);
  wire [11:0] patterns [11:0];
  wire [11:0] seq_freq [2:0];
  wire [1:0] ivol [2:0];
  wire seq_tick = !pattern_clock[3]; //(pattern_clock == 15);
  reg [3:0] seq_clock;

  assign patterns[0]  = 12'h001;
  assign patterns[1]  = 12'h001;
  assign patterns[2]  = 12'h002;
  assign patterns[3]  = 12'h003;
  assign patterns[4]  = 12'h841;
  assign patterns[5]  = 12'h851;
  assign patterns[6]  = 12'h862;
  assign patterns[7]  = 12'h873;
  assign patterns[8]  = 12'h941;
  assign patterns[9]  = 12'h951;
  assign patterns[10] = 12'h962;
  assign patterns[11] = 12'h973;

  // pattern selector 0 drives both channels 0 and 1
  pattern_selector ps0(
    .pattern(patterns[seq_clock][3:0]),
    .row(pattern_clock),
    .freq(seq_freq[0])
  );

  pattern_selector ps1(
    .pattern(patterns[seq_clock][7:4]),
    .row(pattern_clock),
    .freq(seq_freq[1])
  );

  pattern_selector ps2(
    .pattern(patterns[seq_clock][11:8]),
    .row(pattern_clock),
    .freq(seq_freq[2])
  );

  instrument0 i0(
    .select(tick_clock),
    .vol(ivol[0])
  );

  instrument1 i1(
    .select(tick_clock),
    .vol(ivol[1])
  );

  instrument2 i2(
    .select(tick_clock),
    .vol(ivol[2])
  );

  always @(posedge seq_tick, negedge rst_n) begin
    if (!rst_n)
      seq_clock <= 0;
    else
      if (seq_clock == 4'hB)
        seq_clock <= 4'h8;
      else
        seq_clock <= seq_clock + 1;
  end

  assign freq0 = seq_freq[0];
  assign freq1 = (seq_freq[0] >> 1); // channel 1 is just channel 0 shifted up one octave
  assign freq2 = seq_freq[1];
  assign freq3 = seq_freq[2];
  assign vol0 = seq_freq[0] > 0 ? ivol[0] : 0;
  assign vol1 = seq_freq[0] > 0 ? ivol[0] : 0;
  assign vol2 = seq_freq[1] > 0 ? ivol[1] : 0;
  assign vol3 = seq_freq[2] > 0 ? ivol[2] : 0;

endmodule
