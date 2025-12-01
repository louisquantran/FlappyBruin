`timescale 1ns / 1ps

// Scaled VGA text scoreboard: draws "Score: XYZ" at top-right of 640x480.
// Uses an 8x8 bitmap font but scales each pixel by SCALE (2 => 16x16-looking chars).

module score_board #(
    parameter int SCALE  = 2,          // pixel scaling factor (2 or 3 is nice)
    parameter int X0     = 640 - 8*10*SCALE - 8,  // left edge of text area
    parameter int Y0     = 16          // top edge of text area
)(
    input  logic [9:0]  x,
    input  logic [9:0]  y,
    input  logic [9:0]  score,   // 0-999
    output logic        on,      // 1 when this pixel is part of the text
    output logic [11:0] rgb      // color of scoreboard text
);

    // Base character cell size and number of characters: "Score: " + 3 digits = 10 chars
    localparam int CHAR_W_BASE = 8;
    localparam int CHAR_H_BASE = 8;
    localparam int NUM_CHARS   = 10;

    // Scaled character size
    localparam int CHAR_W = CHAR_W_BASE * SCALE;
    localparam int CHAR_H = CHAR_H_BASE * SCALE;

    // Local coordinates inside the (scaled) text block
    logic [9:0] rel_x, rel_y;
    logic       in_block;

    assign in_block = (x >= X0) && (x < X0 + CHAR_W*NUM_CHARS) &&
                      (y >= Y0) && (y < Y0 + CHAR_H);

    always_comb begin
        if (in_block) begin
            rel_x = x - X0;
            rel_y = y - Y0;
        end else begin
            rel_x = '0;
            rel_y = '0;
        end
    end

    // Convert score to 3 decimal digits (hundreds, tens, ones)
    logic   [3:0] d0, d1, d2;  // ones, tens, hundreds
    integer       tmp;

    always_comb begin
        tmp = score;
        if (tmp < 0)
            tmp = 0;
        if (tmp > 999)
            tmp = 999;

        d0 = tmp % 10;
        tmp = tmp / 10;
        d1 = tmp % 10;
        tmp = tmp / 10;
        d2 = tmp % 10;
    end

    // Character codes (small custom charset)
    localparam logic [4:0]
        CH_SPACE = 5'd0,
        CH_S     = 5'd1,
        CH_c     = 5'd2,
        CH_o     = 5'd3,
        CH_r     = 5'd4,
        CH_e     = 5'd5,
        CH_COLON = 5'd6,
        CH_0     = 5'd7,
        CH_1     = 5'd8,
        CH_2     = 5'd9,
        CH_3     = 5'd10,
        CH_4     = 5'd11,
        CH_5     = 5'd12,
        CH_6     = 5'd13,
        CH_7     = 5'd14,
        CH_8     = 5'd15,
        CH_9     = 5'd16;

    function automatic logic [4:0] digit_to_char(input logic [3:0] d);
        case (d)
            4'd0:    digit_to_char = CH_0;
            4'd1:    digit_to_char = CH_1;
            4'd2:    digit_to_char = CH_2;
            4'd3:    digit_to_char = CH_3;
            4'd4:    digit_to_char = CH_4;
            4'd5:    digit_to_char = CH_5;
            4'd6:    digit_to_char = CH_6;
            4'd7:    digit_to_char = CH_7;
            4'd8:    digit_to_char = CH_8;
            4'd9:    digit_to_char = CH_9;
            default: digit_to_char = CH_SPACE;
        endcase
    endfunction

    // "Score: XYZ"  => S c o r e : [space] hundreds tens ones
    function automatic logic [4:0] char_for_index(
        input logic [3:0] idx,
        input logic [3:0] hd, td, od
    );
        case (idx)
            4'd0: char_for_index = CH_S;
            4'd1: char_for_index = CH_c;
            4'd2: char_for_index = CH_o;
            4'd3: char_for_index = CH_r;
            4'd4: char_for_index = CH_e;
            4'd5: char_for_index = CH_COLON;
            4'd6: char_for_index = CH_SPACE;
            4'd7: char_for_index = (hd == 0) ? CH_SPACE : digit_to_char(hd);
            4'd8: char_for_index = ((hd == 0) && (td == 0)) ? CH_SPACE : digit_to_char(td);
            4'd9: char_for_index = digit_to_char(od);
            default: char_for_index = CH_SPACE;
        endcase
    endfunction

    // 8x8 bitmap font: one row of pixels for given char+row
    function automatic logic [7:0] font_row(
        input logic [4:0] ch,
        input logic [2:0] row
    );
        case (ch)
            // SPACE
            CH_SPACE: begin
                font_row = 8'b00000000;
            end

            // 'S'
            CH_S: begin
                case (row)
                    3'd0: font_row = 8'b00111110;
                    3'd1: font_row = 8'b01000000;
                    3'd2: font_row = 8'b01111100;
                    3'd3: font_row = 8'b00000110;
                    3'd4: font_row = 8'b00000010;
                    3'd5: font_row = 8'b01111100;
                    3'd6: font_row = 8'b00000000;
                    3'd7: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase
            end

            // 'c'
            CH_c: begin
                case (row)
                    3'd0: font_row = 8'b00000000;
                    3'd1: font_row = 8'b00000000;
                    3'd2: font_row = 8'b00111100;
                    3'd3: font_row = 8'b01000000;
                    3'd4: font_row = 8'b01000000;
                    3'd5: font_row = 8'b00111100;
                    3'd6: font_row = 8'b00000000;
                    3'd7: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase
            end

            // 'o'
            CH_o: begin
                case (row)
                    3'd0: font_row = 8'b00000000;
                    3'd1: font_row = 8'b00000000;
                    3'd2: font_row = 8'b00111100;
                    3'd3: font_row = 8'b01000010;
                    3'd4: font_row = 8'b01000010;
                    3'd5: font_row = 8'b00111100;
                    3'd6: font_row = 8'b00000000;
                    3'd7: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase
            end

            // 'r'
            CH_r: begin
                case (row)
                    3'd0: font_row = 8'b00000000;
                    3'd1: font_row = 8'b00000000;
                    3'd2: font_row = 8'b01111100;
                    3'd3: font_row = 8'b00100010;
                    3'd4: font_row = 8'b00100000;
                    3'd5: font_row = 8'b00100000;
                    3'd6: font_row = 8'b00000000;
                    3'd7: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase
            end

            // 'e'
            CH_e: begin
                case (row)
                    3'd0: font_row = 8'b00000000;
                    3'd1: font_row = 8'b00000000;
                    3'd2: font_row = 8'b00111100;
                    3'd3: font_row = 8'b01000010;
                    3'd4: font_row = 8'b01111110;
                    3'd5: font_row = 8'b01000000;
                    3'd6: font_row = 8'b00111100;
                    3'd7: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase
            end

            // ':'
            CH_COLON: begin
                case (row)
                    3'd0: font_row = 8'b00000000;
                    3'd1: font_row = 8'b00011000;
                    3'd2: font_row = 8'b00011000;
                    3'd3: font_row = 8'b00000000;
                    3'd4: font_row = 8'b00011000;
                    3'd5: font_row = 8'b00011000;
                    3'd6: font_row = 8'b00000000;
                    3'd7: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase
            end

            // '0'
            CH_0: begin
                case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01000010;
                    3'd2: font_row = 8'b01000010;
                    3'd3: font_row = 8'b01000010;
                    3'd4: font_row = 8'b01000010;
                    3'd5: font_row = 8'b00111100;
                    3'd6: font_row = 8'b00000000;
                    3'd7: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase
            end

            // '1'
            CH_1: begin
                case (row)
                    3'd0: font_row = 8'b00011000;
                    3'd1: font_row = 8'b00101000;
                    3'd2: font_row = 8'b00001000;
                    3'd3: font_row = 8'b00001000;
                    3'd4: font_row = 8'b00001000;
                    3'd5: font_row = 8'b00111100;
                    3'd6: font_row = 8'b00000000;
                    3'd7: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase
            end

            // '2'
            CH_2: begin
                case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01000010;
                    3'd2: font_row = 8'b00000110;
                    3'd3: font_row = 8'b00011000;
                    3'd4: font_row = 8'b01100000;
                    3'd5: font_row = 8'b01111110;
                    3'd6: font_row = 8'b00000000;
                    3'd7: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase
            end

            // '3'
            CH_3: begin
                case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b00000010;
                    3'd2: font_row = 8'b00011100;
                    3'd3: font_row = 8'b00000010;
                    3'd4: font_row = 8'b00000010;
                    3'd5: font_row = 8'b00111100;
                    3'd6: font_row = 8'b00000000;
                    3'd7: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase
            end

            // '4'
            CH_4: begin
                case (row)
                    3'd0: font_row = 8'b00001100;
                    3'd1: font_row = 8'b00010100;
                    3'd2: font_row = 8'b00100100;
                    3'd3: font_row = 8'b01111110;
                    3'd4: font_row = 8'b00000100;
                    3'd5: font_row = 8'b00000100;
                    3'd6: font_row = 8'b00000000;
                    3'd7: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase
            end

            // '5'
            CH_5: begin
                case (row)
                    3'd0: font_row = 8'b01111110;
                    3'd1: font_row = 8'b01000000;
                    3'd2: font_row = 8'b00111100;
                    3'd3: font_row = 8'b00000010;
                    3'd4: font_row = 8'b00000010;
                    3'd5: font_row = 8'b00111100;
                    3'd6: font_row = 8'b00000000;
                    3'd7: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase
            end

            // '6'
            CH_6: begin
                case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01000000;
                    3'd2: font_row = 8'b01111100;
                    3'd3: font_row = 8'b01000010;
                    3'd4: font_row = 8'b01000010;
                    3'd5: font_row = 8'b00111100;
                    3'd6: font_row = 8'b00000000;
                    3'd7: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase
            end

            // '7'
            CH_7: begin
                case (row)
                    3'd0: font_row = 8'b01111110;
                    3'd1: font_row = 8'b00000010;
                    3'd2: font_row = 8'b00001100;
                    3'd3: font_row = 8'b00010000;
                    3'd4: font_row = 8'b00100000;
                    3'd5: font_row = 8'b00100000;
                    3'd6: font_row = 8'b00000000;
                    3'd7: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase
            end

            // '8'
            CH_8: begin
                case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01000010;
                    3'd2: font_row = 8'b00111100;
                    3'd3: font_row = 8'b01000010;
                    3'd4: font_row = 8'b01000010;
                    3'd5: font_row = 8'b00111100;
                    3'd6: font_row = 8'b00000000;
                    3'd7: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase
            end

            // '9'
            CH_9: begin
                case (row)
                    3'd0: font_row = 8'b00111100;
                    3'd1: font_row = 8'b01000010;
                    3'd2: font_row = 8'b00111110;
                    3'd3: font_row = 8'b00000010;
                    3'd4: font_row = 8'b00000010;
                    3'd5: font_row = 8'b00111100;
                    3'd6: font_row = 8'b00000000;
                    3'd7: font_row = 8'b00000000;
                    default: font_row = 8'b00000000;
                endcase
            end

            default: begin
                font_row = 8'b00000000;
            end
        endcase
    endfunction

    // Scaled character indexing
    logic [9:0] cell_x_base, cell_y_base;
    logic [3:0] char_idx;
    logic [2:0] col, row;
    logic [4:0] char_code;
    logic [7:0] bits;

    always_comb begin
        on  = 1'b0;
        rgb = 12'h000;

        if (in_block) begin
            // Map scaled coordinates back to base 8x8 grid
            cell_x_base = rel_x / SCALE;
            cell_y_base = rel_y / SCALE;

            char_idx = cell_x_base / CHAR_W_BASE;    // 0..9
            col      = cell_x_base[2:0];             // 0..7 within char
            row      = cell_y_base[2:0];             // 0..7 within char

            char_code = char_for_index(char_idx, d2, d1, d0);
            bits      = font_row(char_code, row);

            if (bits[7-col]) begin
                on  = 1'b1;
                rgb = 12'hFFF;   // white text
            end
        end
    end

endmodule
