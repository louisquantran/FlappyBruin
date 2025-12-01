`timescale 1ns / 1ps

module clk_gen(
    input logic clk_100MHz,
    input logic reset,
    
    output logic clk_25MHz,
    output logic clk_60Hz,
    output logic clk_5Hz
    );
    
    // Generate 25Mhz clk(60hz) for vga_controller and other object's movement
    logic  [1:0] c_25MHz;
    assign clk_25MHz = (c_25MHz == 0) ? 1 : 0; // assert tick 1/4 of the time
    
    always_ff @(posedge clk_100MHz or posedge reset) begin
		if(reset) begin
		  c_25MHz <= 0;
		end else begin
		  c_25MHz <= c_25MHz + 1;
		end
	end
	
	// Generate 60Hz clk (1 cycle for scanning whole display buffer)
	int max_60Hz = 833_333 - 1;;  
    logic [19:0] c_60Hz;

    always_ff @(posedge clk_100MHz or posedge reset) begin
        if (reset) begin
            c_60Hz    <= 20'b0;
            clk_60Hz <= 1'b0;
        end else begin
            if (c_60Hz == max_60Hz) begin
                c_60Hz    <= 20'b0;
                clk_60Hz <= ~clk_60Hz;
            end else begin
                c_60Hz <= c_60Hz + 1'b1;
            end
        end
    end
	
	// Generate 5Hz clk
    int max_5Hz = 10_000_000 - 1;
    logic [23:0] c_5Hz;

    always_ff @(posedge clk_100MHz or posedge reset) begin
        if (reset) begin
            c_5Hz   <= 24'd0;
            clk_5Hz <= 1'b0;
        end else begin
            if (c_5Hz == max_5Hz) begin
                c_5Hz   <= 24'd0;
                clk_5Hz <= ~clk_5Hz;   // toggle every 0.1 s → 5 Hz
            end else begin
                c_5Hz <= c_5Hz + 1'b1;
            end
        end
    end
endmodule
