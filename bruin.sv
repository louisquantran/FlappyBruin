`timescale 1ns / 1ps

module bruin(
    input logic clk,
    input logic rst,
    input logic flap_btn,
    output logic [11:0] bruin_color,
    output logic [8:0] x,
    output logic [8:0] y,
    output logic [3:0] high,
    output logic [3:0] width
    );
    
    assign high = 4'b1010;
    assign width = 4'b1010;
   
    logic [8:0] y_0 = 9'b011110000; // 240
    logic [8:0] up_div = 9'b000101000; // 40
    logic [8:0] max_high = 9'b000000101; // 10/2=5
    assign x = 9'b011001000; // 200

    assign bruin_color = 12'b111111110000; // yellow/gold?
    
    always_ff@(posedge flap_btn or posedge rst) begin
        if (rst) begin
            y = y_0;
        end else begin
            if (y - up_div > 5) begin
                y = y - up_div;
            end else begin
                y = max_high;
            end
        end
    end
    
endmodule
