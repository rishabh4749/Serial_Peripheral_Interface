`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.01.2024 16:16:37
// Design Name: 
// Module Name: des
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


module des(
input clk, //System clock
input reset, //Asynchronous reset
input [15:0] datain, //Data input by the user
output spi_cs_l, //SPI active low chip select
output spi_sclk, //SPI bus clock whose trigger would be given by master to slave
output spi_data,//SPI bus data
output [4:0] counter 
    );
  reg [15:0] MOSI; //16 bit register representing Master Out Slave In data line
  reg [4:0] count; //5 bit Control Counter
  reg cs_l; //SPI active low chip select
  reg sclk; //SPI bus clock
  reg [2:0] state; //3 bit register to control states 
  
  always @ (posedge clk  or posedge reset) //Since there is asynchronous reset we need to add reset to the sensitivity list along with clock trigger
  
  begin
  
  if(reset) //If reset is active the initialise the registers to their reset values.
  begin 
  MOSI<=16'b0; 
  count<=5'd16;
  cs_l<=1'b1;
  sclk<=1'b0;
  end
  
  else begin //If reset is inactive then proceed with normal SPI communication execution
  
  case(state)
  
  0: //Initial state of the SPI slave where no significant action would be performed except the transition to the next state.
  begin 
  sclk<=1'b0; //Clock is set to 0
  cs_l<=1'b1; //Chip select being high indicates that Slave device is not yet selected hence is not ready for the data transfer.
  state<=1; //Transition to the next state.
  end
  
  1:
  begin
  sclk<=1'b0;
  cs_l<=1'b0; //Activation/Selection of the Slave Device
  MOSI<=datain[count-1]; //Loading of the data to be transmitted
  count<=count-1; //Updation of the count register for the access of the next bit
  state<=2; //Transition to the next state
  end
  
  2:
  begin
  sclk<=1'b1; //Clock set to high
  if(count>0) //If count is greater than 0, it implies that there are more bit left to be transmitted
  state<=1; //Hence we need to go back to state 1 because that's where our transmission process takes place
  else
  begin
  count<=16; //Count equal to 16 signifies that there are no bits left to be transmitted
  state<=0; //If no bits left to be transmitted then we need to go back to state 0
  end
  end
  
  default:state<=0;
  
  endcase
  
  end
  end
  
  //Here we connect the internal signals to the output ports so as to facilitate smooth interaction of our SPI module with other external devices or modules.
  assign spi_cs_l = cs_l;
  assign spi_sclk=sclk;
  assign spi_data=MOSI;
  assign counter = count;

  
endmodule
