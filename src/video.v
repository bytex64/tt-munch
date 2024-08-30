module munch(
  input wire [6:0] counter,
  input wire [6:0] hpos,
  input wire [6:0] vpos,
  output wire [2:0] level
);
  wire [6:0] munch;
  assign munch[0] = (vpos ^ (counter - 0)) == hpos;
  assign munch[1] = (vpos ^ (counter - 1)) == hpos;
  assign munch[2] = (vpos ^ (counter - 2)) == hpos;
  assign munch[3] = (vpos ^ (counter - 3)) == hpos;
  assign munch[4] = (vpos ^ (counter - 4)) == hpos;
  assign munch[5] = (vpos ^ (counter - 5)) == hpos;
  assign munch[6] = (vpos ^ (counter - 6)) == hpos;

  assign level = (munch[0] ? 7 :
    (munch[1] ? 6 :
     (munch[2] ? 5 :
      (munch[3] ? 4 :
       (munch[4] ? 3 :
        (munch[5] ? 2 :
         (munch[6] ? 1 :
          0)))))));
endmodule

module chargen(
  input wire [9:0] x,
  input wire [9:0] y,
  input wire [3:0] character,
  input wire [9:0] hpos,
  input wire [9:0] vpos,
  output wire pixel
);
  wire [9:0] charmap [14:0];
  wire [9:0] segments;

  /* digits 0-9
  assign charmap[0] = 10'b0000111111;
  assign charmap[1] = 10'b0000000110;
  assign charmap[2] = 10'b0001011011;
  assign charmap[3] = 10'b0001001111;
  assign charmap[4] = 10'b0001100110;
  assign charmap[5] = 10'b0001101101;
  assign charmap[6] = 10'b0001111101;
  assign charmap[7] = 10'b0000000111;
  assign charmap[8] = 10'b0001111111;
  assign charmap[9] = 10'b0001101111;
  */
  assign charmap[0]  = 10'b0000000000;  // space
  assign charmap[1]  = 10'b0001110111;  // A
  assign charmap[2]  = 10'b0000111001;  // C
  assign charmap[3]  = 10'b0001111001;  // E
  assign charmap[4]  = 10'b0001110110;  // H
  assign charmap[5]  = 10'b0110110000;  // K
  assign charmap[6]  = 10'b0000111000;  // L
  assign charmap[7]  = 10'b0001110011;  // P
  assign charmap[8]  = 10'b0101110011;  // R
  assign charmap[9]  = 10'b0001101101;  // S
  assign charmap[10] = 10'b1000000001;  // T
  assign charmap[11] = 10'b0100100110;  // V
  assign charmap[12] = 10'b1000001111;  // D
  assign charmap[13] = 10'b0010110000;  // Y
  assign charmap[14] = 10'b0000111111;  // O

  assign segments = charmap[character];

  assign pixel = (segments[0] && hpos >= x && hpos <= x + 50 && vpos == y)
               | (segments[1] && hpos == x + 50 && vpos >= y && vpos <= y + 50)
               | (segments[2] && hpos == x + 50 && vpos >= y + 50 && vpos <= y + 100)
               | (segments[3] && hpos >= x && hpos <= x + 50 && vpos == y + 100)
               | (segments[4] && hpos == x && vpos >= y + 50 && vpos <= y + 100)
               | (segments[5] && hpos == x && vpos >= y && vpos <= y + 50)
               | (segments[6] && hpos >= x && hpos <= x + 50 && vpos == y + 50)
               | (segments[7] && hpos >= x && hpos <= x + 50 && vpos >= y && vpos <= y + 50
                  && (y - vpos) == (hpos - (x + 50)))
               | (segments[8] && hpos >= x && hpos <= x + 50 && vpos >= y + 50 && vpos <= y + 100
                  && ((y + 50) - vpos) == (x - hpos))
               | (segments[9] && hpos == x + 25 && vpos >= y && vpos <= y + 100);
endmodule

parameter C_sp = 4'd0;
parameter C_A  = 4'd1;
parameter C_C  = 4'd2;
parameter C_E  = 4'd3;
parameter C_H  = 4'd4;
parameter C_K  = 4'd5;
parameter C_L  = 4'd6;
parameter C_P  = 4'd7;
parameter C_R  = 4'd8;
parameter C_S  = 4'd9;
parameter C_T  = 4'd10;
parameter C_V  = 4'd11;
parameter C_D  = 4'd12;
parameter C_Y  = 4'd13;
parameter C_O  = 4'd14;

module text(
  input wire [9:0] x,
  input wire [9:0] y,
  input wire [23:0] str,
  input wire [9:0] hpos,
  input wire [9:0] vpos,
  output wire pixel
);
  wire [3:0] str_chars [5:0];
  wire [2:0] h_dist = (hpos - x) >> 6;
  wire [2:0] char_idx = h_dist;
  wire chargen_pixel;
  assign {
    str_chars[5],  str_chars[4], str_chars[3],  str_chars[2],
    str_chars[1],  str_chars[0]
  } = str;

  chargen chargen(
    .x(x + char_idx * 10'd64),
    .y(y),
    .character(str_chars[char_idx]),
    .hpos(hpos),
    .vpos(vpos),
    .pixel(chargen_pixel)
  );

  assign pixel = hpos >= x && hpos < x + (6 * 64) ? chargen_pixel : 0;
endmodule

module text_sequencer(
  input wire [1:0] selector,
  input wire [9:0] hpos,
  input wire [9:0] vpos,
  input wire [1:0] stage,
  input wire [3:0] stage_timer,
  output wire pixel
);

  wire [23:0] words [6:0];
  wire [2:0] word_select;

  assign words[0] = {C_sp, C_sp, C_sp, C_T, C_A, C_E};
  assign words[1] = {C_sp, C_P, C_E, C_E, C_L, C_S};
  assign words[2] = {C_sp, C_sp, C_K, C_C, C_A, C_H};
  assign words[3] = {C_T, C_A, C_E, C_P, C_E, C_R};
  assign words[4] = {C_sp, C_Y, C_D, C_A, C_E, C_R};
  assign words[5] = {C_sp, C_sp, C_sp, C_sp, C_K, C_O};
  assign words[6] = {C_sp, C_sp, C_E, C_V, C_A, C_R};

  assign word_select = (stage > 0 ? {stage == 3 && selector == 2'd2, selector} :
    (stage_timer != 0 ? 3'd4 : 3'd5));

  text text_gen(
    .x(10'd100),
    .y(10'd280),
    .str(words[word_select]),
    .hpos(hpos),
    .vpos(vpos),
    .pixel(pixel)
  );
endmodule
