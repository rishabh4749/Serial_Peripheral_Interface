`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.01.2024 19:34:17
// Design Name: 
// Module Name: tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb(

    );
    reg clk;
    reg reset;
    reg [15:0] datain;
    
    wire spi_cs_l;
    wire spi_sclk;
    wire spi_data;
    wire [4:0] counter;
    
    always #5 clk=~clk;
    
    des dut(.clk(clk),.reset(reset),.counter(counter),.datain(datain),.spi_cs_l(spi_cs_l),.spi_sclk(spi_sclk),.spi_data(spi_data));
    initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    clk<=0;
    reset<=1;
    datain<=0;
    #10 reset<=1'b0;
    #10 datain<=16'hA569;
    #335 datain<=16'h2563;
    #335 datain<=16'h6A61;
    #335 datain<=16'hA265;
    #335 datain<=16'h7564;
    end
endmodule
