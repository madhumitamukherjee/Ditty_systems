`timescale 1ns / 100ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   23:39:18 11/10/2015
// Design Name:   cache_2wsa
// Module Name:   C:/Users/Dadu/OneDrive/Courses/ECE585_MSD_Teuscher/Homework/Homework4/IP/simX/Cache_2wsa/cache_2wsa_tb.v
// Project Name:  Cache_2wsa
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: cache_2wsa
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// READOPERATION FULLY SUPPORTED BY DEBLEENA........................
////////////////////////////////////////////////////////////////////////////////

module cache_2wsa_tb;

	// Inputs
	reg clock;
	reg reset_n;
	reg [15:0] addr_cpu;
	reg rd_cpu;
	reg wr_cpu;
	reg ready_mem;

	// Outputs
	wire [15:0] addr_mem;
	wire rd_mem;
	wire wr_mem;
	wire stall_cpu;

	// Bidirs
	wire [7:0] data_cpu;
	wire [7:0] data_mem;
	
	reg [7:0] dcpu;
	reg [7:0] wcpu;
	reg [7:0] dmem;
	reg [7:0] wmem;
	
	// Instantiate the Unit Under Test (UUT)
	cache_2wsa uut (
		.clock(clock), 
		.reset_n(reset_n), 
		.data_cpu(data_cpu), 
		.data_mem(data_mem), 
		.addr_cpu(addr_cpu), 
		.addr_mem(addr_mem), 
		.rd_cpu(rd_cpu), 
		.wr_cpu(wr_cpu), 
		.rd_mem(rd_mem), 
		.wr_mem(wr_mem), 
		.stall_cpu(stall_cpu), 
		.ready_mem(ready_mem)
	);

	assign data_cpu = wr_cpu? wcpu : 8'dZ;
	assign data_mem = !wr_mem? dmem : 8'dZ;

	initial begin
	clock = 1'd0;
	forever
	#10 clock = ~clock;
	end
	
	task delay;
	begin
	@(negedge clock);
	end
	endtask		
		
    task initialized_input;
    begin
    reset_n = 0;
	addr_cpu = 0;
	rd_cpu = 0;
	wr_cpu = 0;
	ready_mem = 1;
	wcpu = 0;
    end
    endtask

    task read_from_location(reg [15:0] read_location);
    begin
    addr_cpu = read_location;
    dcpu = data_cpu;
    delay;
    rd_cpu = 1'd1;
    dcpu = data_cpu;
    end
    endtask 

    task write_in_location(reg [15:0] write_location, reg [7:0] write_data);
    begin    
    wcpu = write_data;
    addr_cpu = write_location;
    delay;
    delay;
    end
    endtask 

    task check_updated_data(reg [15:0] updated_location);
    begin     
    rd_cpu = 1;
    read_from_location(16'b0000_0000_1001_0011);
    delay;
    rd_cpu = 1'd0;
    delay;
    delay; 
    end
    endtask

    task Read_MM;
    begin        
	@(posedge rd_mem);
	ready_mem = 0;	
	end
	endtask
	
	task Update_MM;
	begin	
	@(posedge wr_mem);
	ready_mem = 0;	
	end    
	endtask	
	
	task WaitFor_MM;
	begin			
	repeat(4)
	delay;
    end
    endtask
      
    task Update_Cache;
    begin 
    repeat(4)
	delay;
    end
    endtask 
       
       
       
       
    initial begin
    initialized_input;
    repeat(4)
    delay;
    reset_n=1;
    delay;

    //for read hit condition
    rd_cpu = 1;
    read_from_location(16'b0000_0000_1001_0011);
    rd_cpu = 1'd0;
    delay;
   
    
    //for write hit condition
    wr_cpu = 1'd1;
    write_in_location(16'b0000_0000_1001_0011, 23);
    wr_cpu = 1'd0;
    delay;
   
    //to check the update
    check_updated_data(16'b0000_0000_1001_0011);
    
    
   //------------------------------------------X For write miss valid data--------------------------/ 
   //-----------------------------------------------------------------------------------------------/
    wr_cpu = 1;
    ready_mem = 1;
       
    write_in_location(16'b1100_0000_1000_1011, 8'h33);    
   
    Read_MM;
   
    WaitFor_MM;
    
    ready_mem = 1;
    delay;		
    dmem = 8'h11;    
    delay;    
    dmem = 8'h22;    
    delay;    
    dmem = 8'h33;    
    delay;    
    dmem = 8'h44;
    
  
    Update_Cache;
    wr_cpu = 1'd0;
    delay;
    
    //------------------------------------------X For write miss Dirty data then Eviction-------------/ 
    //-----------------------------------------------------------------------------------------------/
    wr_cpu = 1;
    ready_mem = 1;
    write_in_location(16'b1100_0000_1001_1011, 8'h88);
       
    
    Update_MM;
   
    
   
    WaitFor_MM;
    
    
    
    ready_mem = 1;
   
    Read_MM;
    
    WaitFor_MM;
  
    ready_mem = 1'd1;
    delay;    		
    dmem = 8'hAA;    
    delay;    
    dmem = 8'hBB;    
    delay;    
    dmem = 8'hCC;    
    delay;    
    dmem = 8'hDD;

   
    Update_Cache;
    wr_cpu = 1'd0;
    	
    repeat(10)
    delay;

   
	#400 $finish;
        
		
	end
      
endmodule

