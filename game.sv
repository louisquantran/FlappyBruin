`timescale 1ns / 1ps

module game(
    input logic clk_100MHz,      // from FPGA
	input logic reset,
	input logic flap,
	output logic hsync, 
	output logic vsync,
	output logic [11:0] rgb
    );
    
    logic game_start = 1'b0;
    
    render rendering(.clk_100MHz(clk_100MHz), .reset(reset), .game_start(game_start), .flap(flap), .hsync(hsync), .vsync(vsync), .rgb(rgb));
    
    always_ff @(posedge clk_100MHz) begin
        if (reset) begin
            game_start <= 1'b0;
        end else begin
            if (flap && !game_start) begin
                game_start <= 1'b1;
            end
        end
    end
    
endmodule
