`timescale 1ns / 1ps

module render(
	input logic clk_100MHz,      // from FPGA
	input logic reset,
	input logic game_start,
	input logic flap,
	output logic hsync, 
	output logic vsync,
	output logic [11:0] rgb,      // 12 FPGA pins for RGB(4 per color) Green: [11:8]; Blue: [7:4]; Red: [3:0]
	output logic lose
);

    
    logic clk_25MHz;
    logic clk_60Hz;
    logic clk_5Hz;
    clk_gen clk_generator(.clk_100MHz(clk_100MHz), .clk_25MHz(clk_25MHz), .clk_60Hz(clk_60Hz), .clk_5Hz(clk_5Hz));
	// ****************************************************************************************
	

	logic [11:0] sky = 12'b1010_1111_0000; // background color (blue)
	
	// Signal Declaration
	logic [11:0] rgb_reg;    // Registar for displaying color on a screen
	logic video_on;         // Same signal as in controller
	logic[9:0] x;
	logic[9:0] y;

    // Instantiate VGA Controller
    vga_controller vga_c(.clk_100MHz(clk_100MHz), .clk_25MHz(clk_25MHz), .reset(reset), .hsync(hsync), .vsync(vsync),
                         .video_on(video_on), .p_tick(), .x(x), .y(y));
                         
                       
    // Bruin Info
    logic [11:0] bruin_color;
    logic [8:0] bruin_x;
    logic [8:0] bruin_y;
    logic [4:0] bruin_high;
    logic [4:0] bruin_width;
    logic bruin_over;

    // Instantiate Bruin
    bruin bruin_bird(.clk_100MHz(clk_100MHz), .clk_25MHz(clk_25MHz), .clk_60Hz(clk_60Hz), .clk_5Hz(clk_5Hz), 
                        .rst(reset), .flap(flap), .game_start(game_start), .bruin_color(bruin_color), .x(bruin_x), .y(bruin_y), 
                        .high(bruin_high), .width(bruin_width), .game_over(bruin_over), .lose(lose));
    
    // Bar Operation
    logic [9:0] x_bar_arr[0:2];
    logic [8:0] y_gap_arr[0:2];
    logic [7:0] width_gap = 120;
    logic [5:0] bar_width = 40;
    logic [11:0] bar_color = 12'b0000_1111_0000;
    logic wraps_bar1;
    logic wraps_bar2;
    logic wraps_bar3;
    logic cnt_en_bar1;
    logic cnt_en_bar2;
    logic cnt_en_bar3;
    logic [9:0] score = 10'd0;
   
    rand_bar_gen bar_1 (
        .clk_25MHz(clk_25MHz),
        .reset(reset),
        .game_start(game_start),
        
        .random_in(9'b001_101_011),
        
        .initial_x(640),
        .set_x(640),
        .x_bar(x_bar_arr[0]),
        .y_gap(y_gap_arr[0]),
        .wraps(wraps_bar1),
        .lose(lose),
        .score(score)
    );
    
    rand_bar_gen bar_2 (
        .clk_25MHz(clk_25MHz),
        .reset(reset),
        .game_start(game_start),
        
        .random_in(9'b110_010_101),
        
        .initial_x(490),
        .set_x(640),
        .x_bar(x_bar_arr[1]),
        .y_gap(y_gap_arr[1]),
        .wraps(wraps_bar2),
        .lose(lose),
        .score(score)
    );
    
    rand_bar_gen bar_3 (
        .clk_25MHz(clk_25MHz),
        .reset(reset),
        .game_start(game_start),
        
        .random_in(9'b101_111_000),
        
        .initial_x(340),
        .set_x(640),
        .x_bar(x_bar_arr[2]),
        .y_gap(y_gap_arr[2]),
        .wraps(wraps_bar3),
        .lose(lose),
        .score(score)
    );
    
    logic        score_on;
    logic [11:0] score_rgb;
    
    score_board #(
        .SCALE(3)
    ) sb_inst (
        .x    (x),
        .y    (y),
        .score(score),
        .on   (score_on),
        .rgb  (score_rgb)
    );
        
    always @(posedge clk_25MHz or posedge reset) begin
        if (reset) begin
            lose <= 1'b0;
            score <= '0;
            cnt_en_bar1 <= 1'b1;
            cnt_en_bar2 <= 1'b1;
            cnt_en_bar3 <= 1'b1;
        end else begin
            if (wraps_bar1 && !cnt_en_bar1) cnt_en_bar1 <= 1'b1;
            else if (wraps_bar2 && !cnt_en_bar2) cnt_en_bar2 <= 1'b1;
            else if (wraps_bar3 && !cnt_en_bar3) cnt_en_bar3 <= 1'b1;
            // Collision detection
            if ((bruin_x+bruin_width/2 >= x_bar_arr[0]-bar_width) &&
                (bruin_x-bruin_width/2 <= x_bar_arr[0]) && 
                (((bruin_y-bruin_high/2) <= (y_gap_arr[0]-width_gap/2)) ||
                ((bruin_y+bruin_high/2) >= (y_gap_arr[0]+width_gap/2)))) begin
                lose <= 1'b1;
            end else if ((bruin_x+bruin_width/2 >= x_bar_arr[1]-bar_width) &&
                (bruin_x-bruin_width/2 <= x_bar_arr[1]) && 
                (((bruin_y-bruin_high/2) <= (y_gap_arr[1]-width_gap/2)) ||
                ((bruin_y+bruin_high/2) >= (y_gap_arr[1]+width_gap/2))) && !lose) begin
                lose <= 1'b1;
            end else if ((bruin_x+bruin_width/2 >= x_bar_arr[2]-bar_width) &&
                (bruin_x-bruin_width/2 <= x_bar_arr[2]) && 
                (((bruin_y-bruin_high/2) <= (y_gap_arr[2]-width_gap/2)) ||
                ((bruin_y+bruin_high/2) >= (y_gap_arr[2]+width_gap/2))) && !lose) begin
                lose <= 1'b1;
            end
            // Scoring
            else if ((bruin_x-bruin_width/2) > x_bar_arr[0] && bruin_y > (y_gap_arr[0]-width_gap/2) 
                    && bruin_y < (y_gap_arr[0]+width_gap/2) && cnt_en_bar1 && !lose) begin
                cnt_en_bar1 <= 1'b0;
                score <= score + 1;
            end else if ((bruin_x-bruin_width/2) > x_bar_arr[1] && bruin_y > (y_gap_arr[1]-width_gap/2) 
                    && bruin_y < (y_gap_arr[1]+width_gap/2) && cnt_en_bar2 && !lose) begin
                cnt_en_bar2 <= 1'b0;
                score <= score + 1;
            end else if ((bruin_x-bruin_width/2) > x_bar_arr[2] && bruin_y > (y_gap_arr[2]-width_gap/2) 
                    && bruin_y < (y_gap_arr[2]+width_gap/2) && cnt_en_bar3 && !lose) begin
                cnt_en_bar3 <= 1'b0;
                score <= score + 1;
            end 
        end
    end
    // RGB Buffer
    always @(posedge clk_25MHz or posedge reset) begin
        if (reset)begin
           rgb_reg <= sky;
        end else begin
           if (score_on) begin
                rgb_reg <= score_rgb;
            // Rendering Bruin
           end else if (x <= (bruin_x+bruin_width/2) && x >= (bruin_x-bruin_width/2)
                && y <= (bruin_y+bruin_high/2) && y >= (bruin_y-bruin_high/2)) begin
                rgb_reg <= bruin_color;
           end else begin
                // Rendering obstacles
                if ((x > x_bar_arr[0]-bar_width && x < x_bar_arr[0])
                    && (y < (y_gap_arr[0]-width_gap/2) || y > (y_gap_arr[0]+width_gap/2))) begin
                    rgb_reg <= bar_color;
                end else if ((x > x_bar_arr[1]-bar_width && x < x_bar_arr[1])
                    && (y < (y_gap_arr[1]-width_gap/2) || y > (y_gap_arr[1]+width_gap/2))) begin
                    rgb_reg <= bar_color;
                end else if ((x > x_bar_arr[2]-bar_width && x < x_bar_arr[2])
                    && (y < (y_gap_arr[2]-width_gap/2) || y > (y_gap_arr[2]+width_gap/2))) begin
                    rgb_reg <= bar_color;
                end else begin
                    rgb_reg <= sky;
                end
            end
        end
    end
    
    // Output
    assign rgb = (video_on) ? rgb_reg : 12'b0;   // while in display area RGB, else all OFF
        
endmodule