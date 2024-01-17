`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.01.2024 11:46:50
// Design Name: 
// Module Name: Instruction_memory
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


module Instruction_memory(
input clk,
input resetn,
input reg mem_valid,
output reg mem_ready,
input [3:0] mem_wstrb,
input [8:0] mem_addr,
input [31:0] mem_wdata,
output reg [31:0] mem_rdata
    );
    
 reg [31:0] memory [0:255]='{default:'0};

	initial begin
		memory[0] = 32'h 3fc00093; //       li      x1,1020
		memory[1] = 32'h 0000a023; //       sw      x0,0(x1)
		memory[2] = 32'h 0000a103; // loop: lw      x2,0(x1)
		memory[3] = 32'h 00110113; //       addi    x2,x2,1
		memory[4] = 32'h 00110113; //       addi    x2,x2,1
		memory[5] = 32'h 0020a023; //       sw      x2,0(x1)
		memory[6] = 32'h ff5ff06f; //       j       <loop>
	end
	

	always @(posedge clk) begin
	  if(resetn) begin  
		mem_ready <= 0;
		if (mem_valid && !mem_ready) begin
			if (mem_addr < 1024) begin
				mem_ready <= 1;
				mem_rdata <= memory[mem_addr >> 2];
				if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
				if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
				if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
				if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
			end
			/* add memory-mapped IO here */
		end
	end   
  end 
    
    
endmodule
