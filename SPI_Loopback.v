//This module is designed to simulate an SPI loopback system, where data sent from the SPI master is received by the SPI slave, and vice versa, through a closed loop.
//This allows for testing SPI communication without requiring separate devices.

`timescale 1ns/1ps

module SPI_Loopback
#(parameter	

system_clk_frequency = 50_000_000, //System Clock Frequency

spi_clk_frequency = 5_000_000, //SPI Clock Frequency
				
data_width = 8,	//Size of the data to be transmitted on the SPI lines
				
CPOL = 0, //Clock Polarity
				
CPHA = 0 //Clock Phase
)

(
	input clk, //System Clock
	input rst_n, //System Reset
	input [data_width-1:0] data_master_in, //Data input to the SPI master.
	input [data_width-1:0] data_slave_in, //Data input to the SPI slave.
	input start_master, //Signal to start the SPI Transmission from the master 
	output finish_master, //Signal indicating that the SPI master has completed the transmission
	output [data_width-1:0]	data_master_out, //Output data from the SPI master
	output [data_width-1:0]	data_slave_out, //Output data from the SPI slave
	output data_valid_slave	 //Signal indicating when valid data is available at the slave's output.
);


wire MISO; //Data line from slave to master
wire MOSI; //Data line from master to slave 
wire chip_select; //Active low chip select line
wire spi_clk; //SPI Clock


//Instantiation of Master and Slave Modules
SPI_Master
#(
	.system_clk_frequency(system_clk_frequency),
	.spi_clk_frequency(spi_clk_frequency),
	.data_width(data_width),
	.CPOL(CPOL),
	.CPHA(CPHA) 
)

u_spi_master(
	.clk(clk),
	.rst_n(rst_n),
	.data_in(data_master_in  ),
	.start(start_master),
	.MISO(MISO),
	.spi_clk(spi_clk),
	.chip_select(chip_select),
	.MOSI(MOSI),
	.finish(finish_master),
	.data_out (data_master_out )
);


SPI_Slave 
#(
	.system_clk_frequency(system_clk_frequency),
	.spi_clk_frequency(spi_clk_frequency),
	.data_width(data_width),
	.CPOL(CPOL),
	.CPHA(CPHA) 
)

u_SPI_Slave(
	.clk (clk),
	.rst_n (rst_n),
	.data_in (data_slave_in),
	.spi_clk (spi_clk),
	.chip_select (chip_select),
	.MOSI(MOSI),
	.MISO(MISO),
	.data_valid (data_valid_slave ),
	.data_out (data_slave_out)
);

endmodule
