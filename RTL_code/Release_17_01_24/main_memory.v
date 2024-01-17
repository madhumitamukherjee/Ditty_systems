`timescale 1ns / 1ps


module main_memory#( 
// Parameters
parameter AWIDTH		= 9,	//Address Bus width
parameter DWIDTH		= 32	    //Data Bus Width
)(
input clk,
input reset_n,
input rd_mem,
input wr_mem,
input [DWIDTH-1:0] data_in,
input [AWIDTH-1:0]  addr_mem,
output reg [DWIDTH-1:0] data_out,
output  ready_mem
    );
    
   reg [DWIDTH-1:0] ram_block [0:511];
   reg [AWIDTH-1:0]  addr;
    
  // Memory initialization
initial
begin
	$readmemb("/home/cse/Thales/Release_17_Jan_2024/memory.txt",ram_block );
end
  
      
      always @(negedge clk) begin
  
    if (wr_mem)
     ram_block[addr_mem] <= data_in;
     addr <= addr_mem;
    end
  
  assign  data_out = ram_block[addr];
  assign ready_mem= (wr_mem | rd_mem ) ? 1'b0:1'b1; 
endmodule
