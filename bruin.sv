`timescale 1ns / 1ps

module bruin(
    input logic clk_100MHz,
    input logic clk_25MHz,
    input logic clk_60Hz,
    input logic clk_5Hz,
    input logic rst,
    input logic flap,
    input logic game_start,
    output logic [11:0] bruin_color,
    output logic [8:0] x,
    output logic [8:0] y,
    output logic [4:0] high,
    output logic [4:0] width,
    output logic game_over,
    input logic lose
    );
    
    assign high = 5'd20;
    assign width = 5'd20;
   
    logic [8:0] y_0 = 9'd240; // 240
    logic [8:0] flap_speed = 9'd80; // Every flap, move up 30 pixel in 30 frames (game is 60 FPS, so half second)
    logic [8:0] flap_rate = 9'd8; // move up 6 pixel
    logic [8:0] falling_rate = 9'd4;
    logic [8:0] falling_speed = 9'd40;
    logic [8:0] max_high = 9'd10; // 20/2=10
    logic [8:0] min_high = 9'd470; // 480 - 10 = 470
    assign x = 9'd200; // 200

    assign bruin_color = 12'b1111_0000_1111; // yellow/gold?
	
	// Capture flap signal in 5Hz
	logic flap_sync0, flap_sync1;
    logic flap_rise;
    
    assign flap_rise = flap_sync0 & ~flap_sync1;  // one-cycle pulse on press

    always_ff @(posedge clk_5Hz or posedge rst) begin
        if (rst) begin
            flap_sync0 <= 1'b0;
            flap_sync1 <= 1'b0;
        end else if (game_start) begin
            flap_sync0 <= flap;
            flap_sync1 <= flap_sync0;
        end
    end
	
    // Update Bruin position in 420Khz (Same as VGA scanning rate)
    logic [8:0] flap_count = 9'b0;
    logic [8:0] falling_count = 9'b0;
    logic [4:0] falling_d = 4'b0;
    logic flap_state_pre = 1'b1;
    logic flap_state_cur = 1'b0;
    
    always_ff @(posedge clk_60Hz or posedge rst) begin
        if (rst) begin
            y <= y_0;
            flap_count <= 9'b0;
            falling_count = 9'b0;
            falling_d = 4'b0;
            flap_state_cur <= 1'b0;
            flap_state_pre <= 1'b1;
            game_over <= 1'b0;
        end else if (game_start) begin
            if (!lose) begin
                if (flap_rise && flap_state_pre == 1 && flap_state_cur == 0) begin
                    flap_state_cur <= 1'b1;
                    flap_state_pre <= 1'b0;
                    flap_count <= 9'b0;
                end else if(!flap_rise && flap_state_pre == 0 && flap_state_cur == 1) begin
                    flap_state_cur <= 1'b0;
                    flap_state_pre <= 1'b1;
                end
                
                if (!falling_d) begin
                    falling_count <= 9'b0;
                end else begin
                    falling_d <= falling_d + 1;
                end
                
                
                if (flap_rise && y - flap_rate >= max_high && flap_count < flap_speed) begin // Flap
                    y <= y - flap_rate;
                    flap_count <= flap_count + flap_rate;
                end else if (y >= min_high) begin
                    y <= min_high;
                    game_over <= 1'b1;
                end else if (falling_count < falling_speed) begin
                    y <= y + falling_rate;
                    falling_count <= falling_count + falling_rate;
                end else if (y <= max_high) begin
                    y <= max_high;
                end else begin
                    
                end
            end
        end
    end
    
endmodule
