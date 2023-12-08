`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.12.2023 12:33:40
// Design Name: 
// Module Name: stage1
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


module stage1#(parameter AWIDTH		= 9,	//Address Bus width
parameter DWIDTH		= 8)(

    input			clock,		//Clock input same as CPU and Memory controller(if MemController work on same freq.)
	input			reset_n,	//Active Low Asynchronous Reset Signal Input

	inout	[DWIDTH-1:0]	data_cpu,	//Parameterized Bi-directional Data bus from CPU
	input	[AWIDTH-1:0]	addr_cpu,	//Parameterized Address bus from CPU
	inout       [DWIDTH-1:0] data_mem, //Parameterized Bi-directional Data bus to Main Memory

	input			rd_cpu,		//Active High Read signal from CPU
	input			wr_cpu 	//Active High WRITE signal from CPU

);
logic		rd_mem; //Active High Read signal to Main Memory
logic       wr_mem; //Active High Write signal to Main Memory
//logic       [DWIDTH-1:0] data_mem; //Parameterized Bi-directional Data bus to Main Memory
logic     [AWIDTH-1:0]	addr_mem;	//Parameterized Address bus to Main Memory
logic     ready_mem;    //Active High Ready signal from Main memory, to know the status of memory
logic     [DWIDTH-1:0] data_in;
logic    [DWIDTH-1:0] data_out;

cache_2wsa cache(
. clock(clock),
.reset_n(reset_n),
.data_cpu(data_cpu),
.data_mem(data_mem),
.addr_cpu(addr_cpu),
.addr_mem(addr_mem),
.rd_cpu(rd_cpu),
.wr_cpu(wr_cpu),
.rd_mem(rd_mem),
.wr_mem(wr_mem),
.ready_mem(ready_mem),
.stall_cpu()
    );
    
main_memory memory(
.clk(clock),
.reset_n(reset_n),
.rd_mem(rd_mem),
.wr_mem(wr_mem),
.data_in(data_mem),
.addr_mem(addr_mem),
.ready_mem(ready_mem),
.data_out(data_mem)
);



/*always@ (posedge clock or negedge reset_n) begin
if (wr_mem)
   data_in<=data_mem;
else if(rd_mem)   
   data_mem <= data_out;   
else
   data_in<= 'b0;
end



    
 always_comb begin
   data_in = wr_mem? data_mem : 'b0;  
   data_mem = rd_mem? data_out : 'b0;
 end 
*/    
endmodule
