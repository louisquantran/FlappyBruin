`timescale 1ns / 1ps

module rand_bar_gen(
    input logic clk_25MHz,
    input logic reset,
    input logic game_start,
    input logic [8:0] random_in,
    
    input logic [9:0] initial_x,
    input logic [9:0] set_x,
    output logic wraps,
    
    output logic [9:0] x_bar,
    output logic [8:0] y_gap,
    input logic lose,
    input logic [9:0] score
);  
    logic [31:0] clk_cnt;   
    
    // Random Operations
    logic [8:0] random;
    always_ff @(posedge clk_25MHz or posedge reset) begin
        if (reset) begin
            random <= random_in;
        end else if(game_start) begin
            if (x_bar == 1) begin
                automatic logic result = random[8] ^ random[7] ^ random[5] ^ random[3] ^ random[2];
                random <= {random[7:0], result};
            end
        end
    end
    
    logic [17:0] lvl1_speed = 250000;
    logic [17:0] lvl2_speed = 200000;
    always_ff @(posedge clk_25MHz or posedge reset) begin
        if (reset) begin   
            wraps <= 1'b0;
            x_bar <= initial_x; 
            y_gap <= 240; // y_gap sets to be in the middle
            clk_cnt <= 1'b0;
        end else if(game_start) begin
            if (!lose) begin
                clk_cnt <= clk_cnt + 1;
                // go left once when clk_cnt reaches 10M, can change accordingly
                if (score < 3) begin
                    if (clk_cnt == lvl1_speed) begin
                        clk_cnt <= '0;
                        if (x_bar == 0) begin
                            wraps <= 1'b1;
                            x_bar <= set_x;
                            if (random <= 120) begin
                                y_gap <= 120;
                            end else if (random >= 360) begin
                                y_gap <= 360; // Reaches the top
                            end else begin
                                y_gap <= random;
                            end
                        end else begin
                            x_bar <= x_bar - 1;
                            wraps <= 1'b0;
                        end
                    end
                end else if (score >= 3) begin
                    if (clk_cnt == lvl2_speed) begin
                        clk_cnt <= '0;
                        if (x_bar == 0) begin
                            wraps <= 1'b1;
                            x_bar <= set_x;
                            if (random <= 120) begin
                                y_gap <= 120;
                            end else if (random >= 360) begin
                                y_gap <= 360; // Reaches the top
                            end else begin
                                y_gap <= random;
                            end
                        end else begin
                            x_bar <= x_bar - 1;
                            wraps <= 1'b0;
                        end
                    end
                end
            end
        end
    end
endmodule
