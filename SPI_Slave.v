`timescale 1ns/1ps

module SPI_Slave

#(parameter	  
  
system_clk_frequency = 50_000_000, //System Clock Frequency -> It synchronizes internal operations like state transitions, data processing, and logic execution.
		
spi_clk_frequency = 5_000_000, //SPI Clock Frequency -> It synchronizes data transmission on MOSI and MISO lines.
				
data_width = 8	, //Size of the data to be transmitted on the SPI lines

//SPI mode selection 
CPOL = 1	, //Clock polarity (CPOL) refers to the default voltage level (HIGH or LOW) of the clock line (SCLK) when no data is being transmitted.

CPHA = 1 // Clock phase (CPHA) determines when data is sampled and captured relative to the clock's edges (rising or falling).
)
(
	input clk, //System clk
	input rst_n	, //System Reset
	input [data_width-1:0] data_in,	//The data sent on the MISO line
	input spi_clk, //SPI Bus Clock
	input chip_select, //Chip Select
	input MOSI,	//MOSI Input
	output MISO, //MISO Output
	output data_valid,
	output reg [data_width-1:0]	data_out //Valid when data_valid is high
);

//Function to get the width of the data
function integer log2(input integer v);
  begin
	log2=0;
	while(v>>log2) 
	  log2=log2+1;
  end
endfunction

//Number of bits required to count the total number of samples for a given data_width.
localparam shift_count = log2(data_width); 

reg	[data_width-1:0] data_reg; //Holds the data being transmitted or recieved.
reg	[shift_count-1:0] sample_count;	//Tracks how many bits have to be sampled during the SPI transmission

//SPI Clock Registers to capture the edge of the SPI Clock
reg	sclk_a;
reg sclk_b;	

wire sclk_posedge;	//Rising edge of the SPI Clock
wire sclk_negedge;	//Falling edge of the SPI Clock

//Chip Select Registers to capture the edge of Chip Select line
reg	cs_n_a;	
reg	cs_n_b;


wire cs_n_negedge; //Chip Select is active low hence data will be latched on the falling edge of the chip select line


wire shift_en	;	//The signal to enable shift register to generate MOSI sequence
wire sample_en	;	//The signal to sample the data on MISO line


//To capture the edge of SPI Clock
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin //Active low reset signal 
		sclk_a <= CPOL;
		sclk_b <= CPOL;
		end 
		else if (!chip_select) begin
		sclk_a <= spi_clk;
		sclk_b <= sclk_a; //Clock B gets assigned the last edge value of clock A
	end
end

//Detection of edges of SPI Clock
assign sclk_posedge = ~sclk_b & sclk_a;
assign sclk_negedge = ~sclk_a & sclk_b;


//To capture the edge of the SPI Clock
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cs_n_a	<= 1'b1;
		cs_n_b	<= 1'b1;
	end else begin
		cs_n_a	<= chip_select		;
		cs_n_b	<= cs_n_a	;
	end
end

//Detection of edge of the chip select line
assign cs_n_negedge = ~cs_n_a & cs_n_b;


generate
	case (CPHA)
	
	//sampl_en enables sampling of the data received on the MISO (Master In, Slave Out) line.
		0: assign sample_en = sclk_posedge;
		1: assign sample_en = sclk_negedge;
		default: assign sampl_en = sclk_posedge;
	endcase
endgenerate

generate
 	case (CPHA)
 	
 	 //shift_en enables shifting data out on the MOSI (Master Out, Slave In) line.
		0: assign shift_en = sclk_negedge;
 		1: assign shift_en = sclk_posedge;
		default: assign shift_en = sclk_posedge;
	endcase
endgenerate

//the register to latch the data_in
//also the shift register to generate the miso
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		data_reg <= 'd0;
		
    //When the chip select (cs_n) signal transitions from high to low, it indicates the start of a new SPI transaction.
	else if(cs_n_negedge)
		data_reg <= data_in;
	else if (!chip_select & shift_en) 
	//The leftmost bit (data_reg[data_width-2:0]) moves one position, and the rightmost bit is padded with 1'b0 (a zero).
		data_reg <= {data_reg[data_width-2:0],1'b0};
	else
		data_reg <= data_reg;
end


//data_reg[data_width-1] refers to the leftmost bit in the data_reg, which is the first bit to be transmitted in SPI communication.
assign MISO = !chip_select ? data_reg[data_width-1] : 1'd0;


//SPI slave samples incoming data from the MOSI (Master-Out-Slave-In) line and stores it in the data_out register.
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) //Active low reset signal
		data_out <= 'd0;
	else if (!chip_select & sample_en) 
		data_out <= {data_out[data_width-2:0],MOSI};
	else
		data_out <= data_out;
end


//This section counts the number of data bits received via the SPI protocol and determine when a complete word of data has been received.
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		sample_count <= 'd0;
	else if (chip_select)
		sample_count <= 'd0;
	else if (!chip_select & sample_en) 
	
	//If the counter sampl_num equals the data width (DATA_WIDTH), it resets to 1 to indicate the start of a new frame.
		if (sample_count == data_width)
			sample_count <= 'd1;
		else
		//Otherwise, it increments the counter (sampl_num + 1'b1) to keep track of the number of sampled bits.
			sample_count <= sample_count + 1'b1;
	else
		sample_count <= sample_count;
end

//This signal is asserted (data_valid = 1) when the counter sampl_num equals the data width (DATA_WIDTH), indicating that a full word of data has been received.
assign data_valid = (sample_count == data_width);

endmodule
