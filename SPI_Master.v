`timescale 1ns/1ps

module SPI_Master

#(parameter	  
  
system_clk_frequency = 50_000_000, //System Clock Frequency -> It synchronizes internal operations like state transitions, data processing, and logic execution.
		
spi_clk_frequency = 5_000_000, //SPI Clock Frequency -> It synchronizes data transmission on MOSI and MISO lines.
				
data_width = 8, //Size of the data to be transmitted on the SPI lines

//SPI mode selection (mode 0 default)
CPOL = 0, //Clock polarity (CPOL) refers to the default voltage level (HIGH or LOW) of the clock line (SCLK) when no data is being transmitted.

CPHA = 0 // Clock phase (CPHA) determines when data is sampled and captured relative to the clock's edges (rising or falling).
)


(
	input clk, //System Clock
	input rst_n, //System Reset
	input [data_width-1:0]	data_in, //The data sent on the MOSI line of size 8 bits
	input start, //A signal to start the SPI transmission
	input MISO, //MISO Input 
	output reg spi_clk, //SPI bus clock
	output reg chip_select, //Chip select
	output MOSI, //MOSI Output
	output reg finish,	//A pluse to indicate the SPI transmission is over and the data_out is valid
	output reg [data_width-1:0] data_out //The data received by MISO and is valid when the finish is high
);

//Function to calculate the number of bits
function integer log2(input integer v);
  begin
	log2=0;
	while(v>>log2) 
	  log2=log2+1;
  end
endfunction

localparam clock_cycle_count = system_clk_frequency/spi_clk_frequency - 1, //This determines the total count required for the system clock to complete one cycle of the SPI clock.
		   shift_width = log2(data_width), //The shift_width parameter calculates the number of bits required to represent the data_width in binary.
		   count_width = log2(clock_cycle_count); //Specifies how many bits are needed to represent the maximum value of clock_cycle_count.

//States of transmission using SPI Protocol
localparam IDLE	= 3'b000, //The SPI module is idle, waiting for a command or data to begin the communication.
			LOAD = 3'b001, //The SPI module loads the data that needs to be sent over the MOSI line.
			SHIFT = 3'b010, //The SPI module starts sending the data one bit at a time, synchronized with the SPI clock.
			DONE = 3'b100; //The SPI transmission or reception is finished, and the module signals that the task is done.

reg [2:0] cstate; //Current state
reg	[2:0] nstate; //Next state

//Registers to capture the edge of sclk
reg	sclk_a;	
reg	sclk_b;

wire sclk_posedge; //Posedge of sclk
wire sclk_negedge; //Negedge of sclk

wire shift_en; //The signal to enable shift register to generate MOSI sequence
wire sample_en; //The signal to sample the data in the MISO sequence, i.e. data coming from the slave to the master 

reg [count_width-1:0] clk_cnt; //Counter to generate sclk
reg	clk_cnt_en; //Enable clk_cnt to generate SPI clock

reg	[shift_width-1:0] shift_cnt; //Count the number of shifts with the maximum vlaue being the shift width parameter
reg	[data_width-1:0] data_reg;	//The register stores the data to be transmitted (MOSI) or received (MISO)

//Counter to generate the SPI clock
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) //Active low asynchronous reset
		clk_cnt <= 'd0;
	else if (clk_cnt_en) 
		if (clk_cnt == clock_cycle_count) //Already reached the maximum value
			clk_cnt <= 'd0; //Disabled
		else //Increment the counter value by 1
			clk_cnt <= clk_cnt + 1'b1;
	else //Don't count if counter is not enabled 
		clk_cnt <= 'd0;
end

//Generation of SPI Clock
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		spi_clk <= CPOL; //Reset is active low asynchronous reset hence that would set the clock to its idle state which is defined by the CPOL.
	else if (clk_cnt_en) 
		if (clk_cnt == clock_cycle_count) //Required number of cycles reached, hence it's time to toggle the SPI clock	
			spi_clk <= ~spi_clk; 
		else //If required number of cycles not reached then keep going without toggling 
			spi_clk <= spi_clk;
	else //If not enabled then idle state
		spi_clk <= CPOL; //Default state
end

//To capture the edge of SPI Clock
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin //Active low asynchronous reset 
		sclk_a <= CPOL;
		sclk_b <= CPOL;
		
		//By using two registers, we can capture both the current and previous states of the clock.
	end else if (clk_cnt_en) begin
		sclk_a <= spi_clk; //This register captures the current state of the SPI Clock
		sclk_b <= sclk_a; //This captures the last state of the SPI Clock
	end
end

//sclk_a holds the current state of SPI Clock, and sclk_b holds the previous state of SPI Clock.
assign sclk_posedge = ~sclk_b & sclk_a;
assign sclk_negedge = ~sclk_a & sclk_b;


generate
	case (CPHA)
	//When CPHA is 0, sampling is done at the positive edge of the SPI Clock
		0: assign sample_en = sclk_posedge; 
		1: assign sample_en = sclk_negedge;
		
		//Since the default mode is 0
		default: assign sample_en = sclk_posedge;
	endcase
endgenerate

generate
 	case (CPHA)
 	//When CPHA is 0, shifting is done at the negative edge of the SPI Clock
		0: assign shift_en = sclk_negedge;
 		1: assign shift_en = sclk_posedge;
 		
 		//Since the default mode is 0
		default: assign shift_en = sclk_negedge;
	endcase
endgenerate


//FSM-1
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) //Asynchronous active low reset
		cstate <= IDLE;
	else //Current state moves to Next state
		cstate <= nstate;
end


//FSM-2
always @(*) begin
	case (cstate)
		IDLE	: nstate = start ? LOAD : IDLE;
		LOAD	: nstate = SHIFT;
		SHIFT	: nstate = (shift_cnt == data_width) ? DONE : SHIFT; //If reach the end of data, then jump to the DONE state 
		DONE	: nstate = IDLE; 
		default: nstate = IDLE; //Since the default mode is 0
	endcase
end


//FSM-3
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin //Asynchronous active low reset
		clk_cnt_en <= 1'b0	;
		data_reg <= 'd0	;
		chip_select	<= 1'b1	; 
		shift_cnt <= 'd0	;
		finish <= 1'b0	;
		
	end else begin
		case (nstate)
		
			IDLE : begin
				clk_cnt_en <= 1'b0	;
				data_reg <= 'd0	;
				chip_select <= 1'b1	;
				shift_cnt <= 'd0	;
				finish <= 1'b0	;
			end
			
			LOAD : begin
				clk_cnt_en <= 1'b1		;
				data_reg <= data_in	;
				chip_select <= 1'b0		;
				shift_cnt <= 'd0		;
				finish <= 1'b0		;
			end
			
			SHIFT : begin
				if (shift_en) begin
					shift_cnt <= shift_cnt + 1'b1 ; //Tracking the number of shifts
					data_reg <= {data_reg[data_width-2:0],1'b0}; //Shifts the data in data_reg left by 1 bit
				end else begin //If shifting is not enabled
					shift_cnt <= shift_cnt	;
					data_reg <= data_reg		;
				end
				clk_cnt_en <= 1'b1	;
				chip_select <= 1'b0	;
				finish <= 1'b0	;
			end
			
			
			DONE : begin
				clk_cnt_en <= 1'b0	;
				data_reg <= 'd0	;
				chip_select <= 1'b1	;
				data_reg <= 'd0	;
				finish <= 1'b1	;
			end
			
			
			default	: begin
				clk_cnt_en <= 1'b0	;
				data_reg <= 'd0	;
				chip_select <= 1'b1	;
				data_reg <= 'd0	;
				finish <= 1'b0	;
			end
			
			
		endcase
	end
end

//Each clock cycle, the most significant bit (data_reg[data_width-1]) is sent out via the MOSI line.
assign MOSI = data_reg[data_width-1];

//Sampling of incoming data from the MISO line and stores it in data_out
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		data_out <= 'd0;
	else if (sample_en) 
		data_out <= {data_out[data_width-1:0],MISO};
	else
		data_out <= data_out;
end

endmodule
