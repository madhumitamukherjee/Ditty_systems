module memory#( 
// Parameters
parameter AWIDTH		= 9,	//Address Bus width
parameter DWIDTH		= 8	    //Data Bus Width
)(
input clk,
input reset_n,
input rd_mem,
input wr_mem,
input [DWIDTH-1:0] data_in,
input [AWIDTH-1:0] addr_mem,
output reg ready_mem,
output reg [DWIDTH-1:0] data_out
    );
    
   reg [DWIDTH-1:0] ram_block [0:1023];
  
  
   always @(posedge clk or negedge reset_n) begin
   if (!reset_n)
   begin
   data_out<='b0;
   ready_mem <= 1'b0;
   end
   else if (wr_mem)
   begin
       ram_block[addr_mem] <= data_in;
       ready_mem <= 1'b1;
   end     
   
   else if (rd_mem)
   begin
       data_out <= ram_block[addr_mem];
       ready_mem <= 1'b1;
   end 
   
   else    
       ready_mem <= 1'b0;
   end    
endmodule
