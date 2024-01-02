`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.09.2023 11:42:49
// Design Name: 
// Module Name: testbench_v2_multi_core_picorv32_v2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is the testbench of multicore picorv32 with different code running. Here the parameter N=2 so two different codes 
//              are running. Thus two memory are also loaded with two different values.  
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench_v2_multi_core_picorv32;

parameter N=2;
    reg clk = 1;
	reg resetn = 0;
	wire [N-1:0] trap;

	always #5 clk = ~clk;

	initial begin
		//if ($test$plusargs("vcd")) begin
		///	$dumpfile("testbench.vcd");
		//	$dumpvars(0, testbench);
		//end
		repeat (100) @(posedge clk);
		resetn <= 1;
		repeat (1000) @(posedge clk);
		$finish;
	end

	wire [N-1:0] mem_valid;
	wire [N-1:0] mem_instr;
	reg [N-1:0] mem_ready;
	wire [N-1:0] [31:0] mem_addr;
	wire [N-1:0] [31:0] mem_wdata;
	wire [N-1:0] [3:0] mem_wstrb;
	reg  [N-1:0] [31:0] mem_rdata;
	wire [N-1:0]        req_core;

for (genvar i=0; i<N; i++) begin
	always @(posedge clk) begin
		if (mem_valid[i] && mem_ready[i]) begin
			if (mem_instr[i])
				$display("ifetch 0x%08x: 0x%08x", mem_addr[i], mem_rdata[i]);
			else if (mem_wstrb[i])
				$display("write  0x%08x: 0x%08x (wstrb=%b)", mem_addr[i], mem_wdata[i], mem_wstrb[i]);
			else
				$display("read   0x%08x: 0x%08x", mem_addr[i], mem_rdata[i]);
		end
	end
end	
	multicore_picorv32 #(
	) uut (
		.clk         (clk        ),
		.resetn      (resetn     ),
		.trap        (trap       ),
		.mem_valid   (mem_valid  ),
		.mem_instr   (mem_instr  ),
		.mem_ready   (mem_ready  ),
		.mem_addr    (mem_addr   ),
		.mem_wdata   (mem_wdata  ),
		.mem_wstrb   (mem_wstrb  ),
		.mem_rdata   (mem_rdata  )
		
	);

	reg [31:0] memory[N-1:0] [0:255];

	initial begin
		memory[0][0] = 32'h 3fc00093; //       li      x1,1020
		memory[0][1] = 32'h 0000a023; //       sw      x0,0(x1)
		memory[0][2] = 32'h 0000a103; // loop: lw      x2,0(x1)
		memory[0][3] = 32'h 00110113; //       addi    x2,x2,1
		memory[0][4] = 32'h 00111113; //       slli    x2,x2,1
		memory[0][5] = 32'h 0020a023; //       sw      x2,0(x1)
		memory[0][6] = 32'h ff5ff06f; //       j       <loop>
	end



	initial begin
		memory[1][0] = 32'h 3fc00093; //       li      x1,1020
		memory[1][1] = 32'h 0000a023; //       sw      x0,0(x1)
		memory[1][2] = 32'h 0000a103; // loop: lw      x2,0(x1)
		memory[1][3] = 32'h 00210113; //       addi    x2,x2,2
        memory[1][4] = 32'h 00210113; //       addi    x2,x2,2
		memory[1][5] = 32'h 0020a023; //       sw      x2,0(x1)
		memory[1][6] = 32'h ff5ff06f; //       j       <loop>
	end

	
for (genvar i=0; i< N; i++) begin
	always @(posedge clk) begin
		mem_ready[i] <= 0;
		if (mem_valid[i] && !mem_ready[i]) begin
			if (mem_addr[i] < 1024) begin
				mem_ready[i] <= 1;
				mem_rdata[i] <= memory[i][mem_addr[i] >> 2];
				if (mem_wstrb[i][0]) memory[i][mem_addr[i] >> 2][ 7: 0] <= mem_wdata[i][ 7: 0];
				if (mem_wstrb[i][1]) memory[i][mem_addr[i] >> 2][15: 8] <= mem_wdata[i][15: 8];
				if (mem_wstrb[i][2]) memory[i][mem_addr[i] >> 2][23:16] <= mem_wdata[i][23:16];
				if (mem_wstrb[i][3]) memory[i][mem_addr[i] >> 2][31:24] <= mem_wdata[i][31:24];
			end
			/* add memory-mapped IO here */
		end
    end
 end
endmodule
