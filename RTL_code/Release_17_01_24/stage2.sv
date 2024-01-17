`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.01.2024 11:38:24
// Design Name: 
// Module Name: stage2
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


module stage2#(
parameter PICO_EN       = 0,
parameter AWIDTH		= 9,	//Address Bus width
parameter DWIDTH_CPU	= 32,	//Data Bus Width
parameter CACHELINES	= 16,
parameter BLOCKSIZE		= 4,
parameter NUMOFSETS		= 8,
parameter VALIDBIT		= 1,
parameter DIRTYBIT		= 1,
parameter USEDBIT		= 1,
parameter TAGWIDTH		= 4)(
input clk,
input resetn,
output reg trap,
output reg mem_instr,
output reg [AWIDTH-1:0] mem_addr,
output reg [DWIDTH_CPU-1:0] mem_wdata,
output reg [3:0] mem_wstrb

    );

    logic mem_valid;
	logic mem_ready;
	logic  [DWIDTH_CPU-1:0] rdata_core;
    logic [AWIDTH-1:0]	addr_mem;
    logic rd_cpu;
    logic wr_cpu;
    logic rd_mem;
    logic wr_mem;
    logic ready_mem;
    logic [DWIDTH_CPU-1:0] mem_rdata;
    logic [DWIDTH_CPU-1:0] data_out;
    logic [DWIDTH_CPU-1:0] data_mem_in;
    logic [DWIDTH_CPU-1:0] data_mem_out;
    logic stall_cpu;
    logic [1:0] counter='b0;
    logic wr_mem_streched;
    logic wr_mem_active;
    
if  (PICO_EN ) begin
   
picorv32  core (
	             	.clk         (clk        ),
	            	.resetn      (resetn     ),
		            .trap        (trap       ),
		            .mem_valid   (mem_valid  ),
		            .mem_instr   (mem_instr  ),
		            .mem_ready   (mem_ready  ),
		            .mem_addr    (mem_addr   ),
		            .mem_wdata   (mem_wdata  ),
		            .mem_wstrb   (mem_wstrb  ),
		            .mem_rdata   (rdata_core )
		            );

Instruction_memory inst_memory(
                   .clk          (clk        ),
                   .resetn       (resetn     ),
                   .mem_valid    (mem_valid  ),
                   .mem_ready    (mem_ready  ),
                   .mem_wstrb    (mem_wstrb  ),
                   .mem_addr     (mem_addr   ),
                   .mem_wdata    (mem_wdata  ),
                   .mem_rdata    (mem_rdata  )
                   );

assign rd_cpu= ~mem_instr & |mem_wstrb;	
assign wr_cpu= ~mem_instr & ~|mem_wstrb;
assign rdata_core = rd_cpu ? data_out : mem_rdata ;
end

else 

ProcessorCoreA dummy_core(
               .clk            (clk          ), 
               .resetn         (resetn       ),
               .fetched_data   (data_out     ),
               .read           (rd_cpu       ), 
               .write          (wr_cpu       ), 
               .address        (mem_addr     ), 
               .write_data     (mem_wdata    ),
               .stall_cpu      (stall_cpu    )
               );



cache_2wsa_modified cache  (
	            	.clock        (clk         ), 
	            	.reset_n      (resetn      ), 
		            .data_in      (mem_wdata   ), 
		            .data_out     (data_out    ),
		            .data_mem_in  (data_mem_in ), 
		            .data_mem_out (data_mem_out), 
	            	.addr_cpu     (mem_addr    ), 
	            	.addr_mem     (addr_mem    ), 
		            .rd_cpu       (rd_cpu      ), 
		            .wr_cpu       (wr_cpu      ), 
		            .rd_mem       (rd_mem      ), 
		            .wr_mem       (wr_mem      ), 
		            .stall_cpu    (stall_cpu   ), 
		            .ready_mem    (ready_mem   )
		            );

main_memory    memory  (
               .clk             (clk              ),
               .reset_n         (resetn           ),
               .rd_mem          (rd_mem           ),
               .wr_mem          (wr_mem           ),
               .data_in         (data_mem_out     ),
               .data_out        (data_mem_in      ),
               .addr_mem        (addr_mem         ),
               .ready_mem       (ready_mem        )
               );

/*always@(posedge clk) begin               
if (wr_mem)
wr_mem_active <=1;
else
wr_mem_active <=0;

end

assign wr_mem_streched=wr_mem | wr_mem_active;*/
endmodule	