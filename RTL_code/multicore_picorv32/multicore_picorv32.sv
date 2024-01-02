`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Thales India Pvt LTD
// Engineer: Madhumita Mukherjee
// 
// Create Date: 11.09.2023 13:30:21
// Design Name: Multi-core configuration of Picorv32   
// Module Name: multicore_picorv32
// Project Name: 
// Target Devices: Virtex UltraScale VCU118 Evaluation Platform
// Tool Versions: Vivado 2020.1
// Description: This is the RTL code for the setting a multicore configuration of Picorv32
// 
// Dependencies: picorv32.v
// 
// Revision:1.1
// 
//////////////////////////////////////////////////////////////////////////////////


module multicore_picorv32
// No of cores required to be connected
 #(parameter N=2)
 (
  input                 clk, resetn,
  output [N-1:0]        trap,
	output [N-1:0]        mem_valid,
	output [N-1:0]        mem_instr,
	input  [N-1:0]        mem_ready,

	output [N-1:0] [31:0] mem_addr,
	output [N-1:0] [31:0] mem_wdata,
	output [N-1:0] [ 3:0] mem_wstrb,
	input  [N-1:0] [31:0] mem_rdata   
    );
    
genvar i;    
    
generate
     for(i=0; i< N; i=i+1) begin
     picorv32 core(
                .clk         (clk           ),
		.resetn      (resetn        ),
		.trap        (trap[i]       ),
		.mem_valid   (mem_valid[i]  ),
		.mem_instr   (mem_instr[i]  ),
		.mem_ready   (mem_ready[i]  ),
		.mem_addr    (mem_addr[i]   ),
		.mem_wdata   (mem_wdata[i]  ),
		.mem_wstrb   (mem_wstrb[i]  ),
		.mem_rdata   (mem_rdata[i]  )
	);    
    end
 endgenerate  
 endmodule
