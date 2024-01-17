`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.01.2024 12:32:18
// Design Name: 
// Module Name: testbench
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


module testbench1;
    reg clk = 1;
	reg resetn = 0;
	wire trap;

	always #5 clk = ~clk;

	initial begin
		//if ($test$plusargs("vcd")) begin
		///	$dumpfile("testbench.vcd");
		//	$dumpvars(0, testbench);
		//end
		repeat (2) @(posedge clk);
		resetn <= 1;
		repeat (25) @(posedge clk);
		$finish;
		
	end	
		
	
	wire mem_instr;
	wire [8:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;
	



	
	stage2 #(
	) uut (
		.clk         (clk        ),
		.resetn      (resetn     ),
		.trap        (trap       ),
		.mem_instr   (mem_instr  ),
	    .mem_addr    (mem_addr   ),
		.mem_wdata   (mem_wdata  ),
		.mem_wstrb   (mem_wstrb  )
	    
	);	
		


endmodule
