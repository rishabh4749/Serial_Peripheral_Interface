`timescale 1ns/1ps

module SPI_Master_tb();

parameter system_clk_frequency = 50_000_000,
		  spi_clk_frequency	= 5_000_000,
		  data_width = 8,
		  CPOL = 1,
		  CPHA = 1;
reg clk;
reg	rst_n;
reg [data_width-1:0] data_in;
reg	start;
reg	MISO;
wire spi_clk;
wire chip_select;
wire MOSI;
wire finish;
wire [data_width-1:0] data_out;

//Clock Generation
initial begin
	clk = 1;
	forever #10 clk = ~clk;
  end
  
//Reset Generation
initial begin
	rst_n = 1'b0;
	#22 rst_n = 1'b1;
  end
  
//Main Block
initial fork
	data_in_generate;
	start_change;
	debug_information;
join

//Generating data_in
task data_in_generate;
begin
	data_in = 'd0;
	@(posedge rst_n)
	data_in <= 8'b10100101;
	@(posedge finish)
	data_in <= 8'b10011010;
	@(negedge finish)
	;
	@(negedge finish)
	#20 $finish;
end
endtask

//Generating Start Signal
task start_change;
begin
	start = 1'b0;
	@(posedge rst_n)
	#20 start <= 1'b1;
	#20 start = 1'b0;
	@(negedge finish)
	#20 start = 1'b1;
	#20 start = 1'b0;
end
endtask

//Display the debug information
task debug_information;
begin
     $monitor("TIME = %d, MOSI = %b, MISO = %b, data_in = %b",$time, MOSI, MISO, data_in);  
end
endtask

//Generation of MISO
generate
	if(CPHA == 0)
		always @(negedge spi_clk) begin
			MISO = $random;
		end
	else
		always @(posedge spi_clk) begin
			MISO = $random;
		end
endgenerate

	initial begin
		$dumpfile("SPI_Master_tb.vcd");
		$dumpvars();
	end
	
//DUT
SPI_Master 
#(
	.system_clk_frequency (system_clk_frequency ),
	.spi_clk_frequency (spi_clk_frequency),
	.data_width(data_width),
	.CPOL(CPOL),
	.CPHA(CPHA)
)

u_spi_master(
	.clk (clk),
	.rst_n (rst_n),
	.data_in (data_in),
	.start (start),
	.MISO(MISO),
	.spi_clk(spi_clk),
	.chip_select(chip_select),
	.MOSI(MOSI),
	.finish(finish),
	.data_out(data_out)
);

endmodule
