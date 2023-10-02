`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.09.2023 16:55:40
// Design Name: 
// Module Name: pico_L1
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


module pico_L1(
	input clk,core,
/*DUVIDA: existem nas maquinas de estado dois write backs, se estamos na cache 1 e p1 escreve numa linha em que
o bloco estava como imediato e com outra tag(write miss) e ao mesmo tempo a cache 2 ....... eh possivel termos 2 write backs ?*/
	//input read,//from cpu
	//input write,
	//input [15:0] write_data,
	
	
	input [1:0] bus_requests,//from other caches: BUS_INVALIDATE=2'b00, BUS_WRITE_MISS=2'b01, BUS_READ_MISS=2'b10;
	input [8:0] bus_request_mem_address,//the position they reffer	
	
	input bus_data_found,//if the other cache says abort mem access 
	input [31:0] bus_data_delivery,//if we ever need a data that's in other cache, there it is
	
	input [31:0] mem_data_delivery,
	
	output [31:0] data_out_cpu,//reading going to cpu

	output cpu_write_back,bus_write_back,//promote upper in the hierarchy, main mem is watching this
	output [8:0] address_out_mem_cpu,address_out_mem_bus,
	output [31:0] data_out_mem_cpu,data_out_mem_bus,//unique data goes to ram

	output bus_reply_abort_mem_access,//announces to the other core we have the data needed
	output [31:0] bus_reply_data_found,//attends bus_request
	
	output [8:0] ask_mem_address,//what they need to find
	output [1:0] bus_reply,//write on bus for another core that's snooping it
	
	
	
	input         resetn,
    output        trap,
	output        mem_valid1,
	output        mem_instr1,
	input         mem_ready1,

	output [8:0] mem_addr1,
	output [31:0] mem_wdata1,
	output [ 3:0] mem_wstrb1,
	input  [31:0] mem_rdata1
	
	);
logic read, write;	
logic [31:0] write_data;
logic [8:0] mem_address;
//logic [31:0] mem_rdata1; //reading going to cpu 
//logic [ 3:0] mem_wstrb1;
//logic [31:0] data_out_cpu;//reading going to cpu 

cache_directlyMapped_32x21bits _CORE1_CACHE_(
		.clk(clk),.core(1'b0),

		.read(read),
		.write(write),
		.write_data(write_data),
		.mem_address(mem_address),

		.bus_requests(bus_requests),
		.bus_request_mem_address(bus_request_mem_address),

		.bus_data_found(bus_data_found),
		.bus_data_delivery(bus_data_delivery),

		.mem_data_delivery(mem_data_delivery),

		.cpu_write_back(cpu_write_back),//<-outputs:
		.bus_write_back(bus_write_back),
		.data_out_cpu(data_out_cpu),
		.data_out_mem_cpu(data_out_mem_cpu),
		.data_out_mem_bus(data_out_mem_bus),
		.address_out_mem_cpu(address_out_mem_cpu),
		.address_out_mem_bus(address_out_mem_bus),

		.bus_reply_abort_mem_access(bus_reply_abort_mem_access),
		.bus_reply_data_found(bus_reply_data_found),

		.ask_mem_address(ask_mem_address),
		.bus_reply(bus_reply)
	);
	
   picorv32 pico_core1(
		.clk         (clk        ),
		.resetn      (resetn     ),
		.trap        (trap       ),
		.mem_valid   (mem_valid1  ),
		.mem_instr   (mem_instr1  ),
		.mem_ready   (mem_ready1  ),
		.mem_addr    (mem_addr1   ),
		.mem_wdata   (mem_wdata1  ),
		.mem_wstrb   (mem_wstrb1  ),
		.mem_rdata   (mem_rdata1  )
	);	
		
	
	assign read  = ~|mem_wstrb1 & mem_instr1 ;
	assign write =  |mem_wstrb1 & ~mem_instr1;
	assign write_data = mem_wdata1;
	assign mem_address = mem_addr1;
	assign data_out_cpu  = mem_rdata1;
endmodule

