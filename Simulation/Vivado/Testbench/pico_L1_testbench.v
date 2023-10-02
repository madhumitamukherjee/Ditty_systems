// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

`timescale 1 ns / 1 ps

module testbench;
	reg clk = 1;
	reg resetn = 0;
	wire trap;

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

	wire mem_valid;
	wire mem_instr;
	reg mem_ready;
	wire [8:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;
	reg  [31:0] mem_rdata;
    wire [31:0] data_out_cpu;
    wire [31:0] data_out_mem_cpu,data_out_mem_bus;
    reg [1:0] bus_requests;
	reg [8:0] bus_request_mem_address;
	reg bus_data_found;
	reg [31:0] bus_data_delivery;
	reg [31:0] mem_data_delivery;
	wire cpu_write_back,bus_write_back;
	wire [8:0] address_out_mem_cpu,address_out_mem_bus;
	wire bus_reply_abort_mem_access;
	wire [31:0] bus_reply_data_found;
	wire [8:0] ask_mem_address;
	wire [1:0] bus_reply;
	
	always @(posedge clk) begin
		if (mem_valid && mem_ready) begin
			if (mem_instr)
				$display("ifetch 0x%08x: 0x%08x", mem_addr, mem_rdata);
			else if (mem_wstrb)
				$display("write  0x%08x: 0x%08x: 0x%08x (wstrb=%b) ", mem_addr, data_out_cpu, mem_wdata, mem_wstrb );
			else
				$display("read   0x%08x: 0x%08x", mem_addr, mem_rdata);
		end
	end

	pico_L1 #(
	) uut (
		.clk         (clk        ),
		.resetn      (resetn     ),
		.trap        (trap       ),
		.mem_valid1   (mem_valid  ),
		.mem_instr1   (mem_instr  ),
		.mem_ready1   (mem_ready  ),
		.data_out_cpu (data_out_cpu),
		.mem_wdata1   (mem_wdata  ),
		.mem_addr1    (mem_addr),
		.mem_wstrb1   (mem_wstrb),
		.data_out_mem_cpu (data_out_mem_cpu),
		.data_out_mem_bus (data_out_mem_bus),
		.mem_rdata1    (mem_rdata),
		.bus_requests (bus_requests),
		.bus_request_mem_address (bus_request_mem_address),
		.bus_data_found(bus_data_found),
		.bus_data_delivery(bus_data_delivery),
		.mem_data_delivery(mem_data_delivery),
		.cpu_write_back(cpu_write_back),
		.bus_write_back(bus_write_back),
		.address_out_mem_cpu(address_out_mem_cpu),
		.address_out_mem_bus(address_out_mem_bus),
		.bus_reply_abort_mem_access(bus_reply_abort_mem_access),
		.bus_reply_data_found(bus_reply_data_found),
		.ask_mem_address(ask_mem_address),
		.bus_reply(bus_reply)
		
		
	);

	reg [31:0] memory [0:255];

	initial begin
		memory[0] = 32'h 3fc00093; //       li      x1,1020
		memory[1] = 32'h 0000a023; //       sw      x0,0(x1)
		memory[2] = 32'h 0000a103; // loop: lw      x2,0(x1)
		memory[3] = 32'h 00110113; //       addi    x2,x2,1
		memory[4] = 32'h 00111113; //       slli    x2,x2,1
		memory[5] = 32'h 0020a023; //       sw      x2,0(x1)
		memory[6] = 32'h ff5ff06f; //       j       <loop>
	end
	

	always @(posedge clk) begin
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

endmodule
