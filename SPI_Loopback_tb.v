
`timescale 1ns/1ps

module SPI_Loopback_tb();

parameter system_clk_frequency = 50_000_000,
		  spi_clk_frequency	= 5_000_000,
		  data_width = 8,
		  CPOL = 0,
		  CPHA = 0;

reg	clk;
reg rst_n;
reg	[data_width-1:0] data_master_in	;
reg	[data_width-1:0] data_slave_in	;
reg	start_master;
wire finish_master;
wire [data_width-1:0] data_master_out;
wire [data_width-1:0] data_slave_out;
wire data_valid_slave;

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
	data_master_in_generate;
	data_slave_in_generate;
	start_change;
join

//Generation of data_master_in
task data_master_in_generate;
begin
	data_master_in = 'd0;
	@(posedge rst_n)
	data_master_in <= 8'b10100101;
	@(posedge finish_master)
	data_master_in <= 8'b10011010;
end
endtask

//Generation of data_slave_in
task data_slave_in_generate;
begin
	data_slave_in = 'd0;
	@(posedge rst_n)
	data_slave_in <= $random;
	@(negedge data_valid_slave)
	#20 $finish;
end
endtask

//Generation of the start signal
task start_change;
begin
	start_master = 1'b0;
	@(posedge rst_n)
	#20 start_master <= 1'b1;
	#20 start_master = 1'b0;
	@(negedge finish_master)
	#20 start_master = 1'b1;
	#20 start_master = 1'b0;
end
endtask


initial begin
	$dumpfile("SPI_Loopback_tb.vcd");
	$dumpvars();
end

//Debug information
reg data_valid_1; 
reg data_valid_2;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    data_valid_1 <= 1'b0;
    data_valid_2 <= 1'b0;
  end else begin
    data_valid_1 <= data_valid_slave;
    data_valid_2 <= data_valid_1;
  end
end

assign data_valid_pos = ~data_valid_2 & data_valid_1;

always @(posedge clk) begin 
  if (data_valid_pos) begin
    if (data_slave_out == data_master_in) begin
      $display("PASS! data_slave_out = %h, data_master_in = %h", 
               data_slave_out, data_master_in); 
    end else begin
      $display("FAIL! data_slave_out = %h, data_master_in = %h", 
               data_slave_out, data_master_in); 
    end
  end
end

always @(posedge clk) begin
	if (data_valid_pos)
		if (data_master_out == data_slave_in)
			$display("PASS! data_m_out = %h, data_s_in = %h", data_master_out, data_slave_in);
		else
			$display("FAIL! data_m_out = %h, data_s_in = %h", data_master_out, data_slave_in);
end

//DUT
SPI_Loopback 
#(
	.system_clk_frequency (system_clk_frequency),
	.spi_clk_frequency (spi_clk_frequency ),
	.data_width(data_width),
	.CPOL(CPOL),
	.CPHA(CPHA)
)

u_SPI_Loopback(
	.clk(clk),
	.rst_n(rst_n),
	.data_master_in(data_master_in),
	.data_slave_in (data_slave_in),
	.start_master (start_master),
	.finish_master (finish_master),
	.data_master_out (data_master_out),
	.data_slave_out (data_slave_out),
	.data_valid_slave (data_valid_slave)
);

endmodule
