/*
============================
4-way Set Associative Cache
============================
*/
// File Name:		cache_4wsa.v
//
//
// ******************************************************************************************************

module cache_4wsa #( 
// Parameters
parameter AWIDTH		= 16,	//Address Bus width
parameter DWIDTH		= 32,	//Data Bus Width
parameter CACHELINES	= 32,
parameter BLOCKSIZE		= 4,
parameter NUMOFSETS		= 8,
parameter VALIDBIT		= 1,
parameter DIRTYBIT		= 1,
parameter USEDBIT		= 1,
parameter TAGWIDTH		= 11
)
(
	input			clock,		//Clock input same as CPU and Memory controller(if MemController work on same freq.)
	input			reset_n,	//Active Low Asynchronous Reset Signal Input

	inout	[DWIDTH-1:0]	data_cpu,	//Parameterized Bi-directional Data bus from CPU
	inout	[DWIDTH-1:0]	data_mem,	//Parameterized Bi-directional Data bus to Main Memory
	
	input	[AWIDTH-1:0]	addr_cpu,	//Parameterized Address bus from CPU
	output	reg[AWIDTH-1:0]	addr_mem,	//Parameterized Address bus to Main Memory

	input			rd_cpu,		//Active High Read signal from CPU
	input			wr_cpu,		//Active High WRITE signal from CPU

	output	reg		rd_mem,		//Active High Read signal to Main Memory
	output	reg		wr_mem,		//Active High Write signal to Main Memory

	output	reg		stall_cpu,	//Active High Stall Signal to CPU, to halt the CPU while undergoing any other operation
	input			ready_mem	//Active High Ready signal from Main memory, to know the status of memory

);

// State Machine Parameters

localparam	IDLE	= 3'd0,	//Please read Description for explanation of States and their operation
		READ		= 3'd1,
		WRITE		= 3'd2,
		READMM		= 3'd3,
		WAITFORMM	= 3'd4,
		UPDATEMM	= 3'd5,
		UPDATECACHE	= 3'd6;

// Internal Wires and Registers

wire	[10:0]	tagdata;
wire	[2:0]	index;
wire	[1:0]	bytsel;
reg	[DWIDTH-1:0] rdata_byte;
reg	[DWIDTH-1:0] wdata_byte;
reg	[DWIDTH-1:0] wmem_byte;
reg	[(DWIDTH*BLOCKSIZE)-1:0] rmem_4byte;
reg	[(DWIDTH*BLOCKSIZE)-1:0] wmem_4byte;	

reg	[3:0] count;	//To count byte transfer between Cache and memory during read and write memory operation, used as shift register.

reg	rdwr; // If read then '1', if write the '0'
reg	we0;	//Active High Write Enable for DATA RAM 0
reg	we1;	//Active High Write Enable for DATA RAM 1
reg	we2;	//Active High Write Enable for DATA RAM 2
reg	we3;	//Active High Write Enable for DATA RAM 3
reg	wet0;	//Active High Write Enable for TAG RAM 0
reg	wet1;	//Active High Write Enable for TAG RAM 1
reg	wet2;	//Active High Write Enable for TAG RAM 2
reg	wet3;	//Active High Write Enable for TAG RAM 3

reg	update_flag; // Internal flag, SET when enters Update MM state. It is used to make reuse of WAITFORMM state for both READMM and UPDATEMM 			//states

// Internal Signals derived from respective data or address buses
wire	hit;
wire	hit_w0;
wire	hit_w1;
wire	hit_w2;
wire	hit_w3;

wire	valid;
wire	vw0;
wire	vw1;
wire	vw2;
wire	vw3;

wire	uw0;
wire	uw1;
wire	uw2;
wire	uw3;

wire	dirty;
wire	dw0;
wire	dw1;
wire	dw2;
wire	dw3;

wire	[(VALIDBIT+USEDBIT+DIRTYBIT+TAGWIDTH-1):0]	rtag0; //14-bits
wire	[(VALIDBIT+USEDBIT+DIRTYBIT+TAGWIDTH-1):0]	rtag1;
wire	[(VALIDBIT+USEDBIT+DIRTYBIT+TAGWIDTH-1):0]	rtag2; 
wire	[(VALIDBIT+USEDBIT+DIRTYBIT+TAGWIDTH-1):0]	rtag3;


wire	[(DWIDTH*BLOCKSIZE)-1:0] rdata0;	
wire	[(DWIDTH*BLOCKSIZE)-1:0] rdata1;
wire	[(DWIDTH*BLOCKSIZE)-1:0] rdata2;	
wire	[(DWIDTH*BLOCKSIZE)-1:0] rdata3;

wire	[DWIDTH-1:0]		 bytew0;
wire	[DWIDTH-1:0]		 bytew1;
wire	[DWIDTH-1:0]		 bytew2;
wire	[DWIDTH-1:0]		 bytew3;

reg	[(DWIDTH*BLOCKSIZE)-1:0] rdata;
reg	[(DWIDTH*BLOCKSIZE)-1:0] wdata;
reg	[(DWIDTH*BLOCKSIZE)-1:0] strdata0;
reg	[(DWIDTH*BLOCKSIZE)-1:0] strdata1;
reg	[(DWIDTH*BLOCKSIZE)-1:0] strdata2;
reg	[(DWIDTH*BLOCKSIZE)-1:0] strdata3;
reg	[(VALIDBIT+USEDBIT+DIRTYBIT+TAGWIDTH-1):0] wtag0;
reg	[(VALIDBIT+USEDBIT+DIRTYBIT+TAGWIDTH-1):0] wtag1;
reg	[(VALIDBIT+USEDBIT+DIRTYBIT+TAGWIDTH-1):0] wtag2;
reg	[(VALIDBIT+USEDBIT+DIRTYBIT+TAGWIDTH-1):0] wtag3;
reg	[(VALIDBIT+USEDBIT+DIRTYBIT+TAGWIDTH-1):0] strtag0;
reg	[(VALIDBIT+USEDBIT+DIRTYBIT+TAGWIDTH-1):0] strtag1;
reg	[(VALIDBIT+USEDBIT+DIRTYBIT+TAGWIDTH-1):0] strtag2;
reg	[(VALIDBIT+USEDBIT+DIRTYBIT+TAGWIDTH-1):0] strtag3;
reg	[AWIDTH-1:0]		 addrlatch;

// State Variables
reg [2:0] state;

// Combinational Logic

assign tagdata = (state == IDLE) ? addr_cpu[15:5] : addrlatch[15:5];
assign index   = (state == IDLE) ? addr_cpu[4:2] : addrlatch[4:2];
assign bytsel  = (state == IDLE) ? addr_cpu[1:0] : addrlatch[1:0];

assign vw0 = rtag0[13];
assign vw1 = rtag1[13];
assign vw2 = rtag2[13];
assign vw3 = rtag3[13];
assign valid = vw0 & vw1 & vw2 & vw3;

assign uw0  =rtag0[12];
assign uw1  =rtag1[12];
assign uw2  =rtag2[12];
assign uw3  =rtag3[12];

assign dw0 = rtag0[11];
assign dw1 = rtag1[11];
assign dw2 = rtag2[11];
assign dw3 = rtag3[11];
assign dirty = dw0 | dw1 | dw2 | dw3;

assign hit_w0 = vw0 & (tagdata == rtag0[10:0]);
assign hit_w1 = vw1 & (tagdata == rtag1[10:0]);
assign hit_w2 = vw2 & (tagdata == rtag2[10:0]);
assign hit_w3 = vw3 & (tagdata == rtag3[10:0]);
assign hit = hit_w0 | hit_w1 | hit_w2 | hit_w3;

assign bytew0 = (bytsel == 2'd0) ? rdata0[31:0] :((bytsel == 2'd1) ? rdata0[63:32] :((bytsel == 2'd2) ? rdata0[95:64] : rdata0[127:96]));
assign bytew1 = (bytsel == 2'd0) ? rdata1[31:0] :((bytsel == 2'd1) ? rdata1[63:32] :((bytsel == 2'd2) ? rdata1[95:64] : rdata1[127:96]));
assign bytew2 = (bytsel == 2'd0) ? rdata2[31:0] :((bytsel == 2'd1) ? rdata2[63:32] :((bytsel == 2'd2) ? rdata2[95:64] : rdata2[127:96]));
assign bytew3 = (bytsel == 2'd0) ? rdata3[31:0] :((bytsel == 2'd1) ? rdata3[63:32] :((bytsel == 2'd2) ? rdata3[95:64] : rdata3[127:96]));

assign data_cpu = (!wr_cpu) ? rdata_byte : 32'dZ;
assign data_mem = wr_mem ? wmem_byte  : 32'dZ;

// Cache Controller State Machine and Logic

always@(posedge clock or negedge reset_n)
begin
	if(!reset_n)
	begin
		addrlatch <= 'd0;
		addr_mem  <= 'd0;
		rd_mem	  <= 'd0;
		wr_mem	  <= 'd0;
		stall_cpu <= 'd0;
		state	  <= IDLE;
		rdata_byte<= 'd0;
		wdata_byte<= 'd0;
		wmem_byte <= 'd0;
		rmem_4byte<= 'd0;
		wmem_4byte<= 'd0;
		wdata	  <= 'd0;
		wtag0	  <= 'd0;
		wtag1	  <= 'd0;
		wtag2	  <= 'd0;
		wtag3	  <= 'd0;
		we0	      <= 1'd0;
		we1	      <= 1'd0;
		we2	      <= 1'd0;
		we3	      <= 1'd0;
		wet0	  <= 1'd0;
		wet1	  <= 1'd0;
		wet2	  <= 1'd0;
		wet3	  <= 1'd0;
		rdwr	  <= 1'd1;
		strdata0  <= 'd0;
		strdata1  <= 'd0;
		strdata2  <= 'd0;
		strdata3  <= 'd0;
		strtag0   <= 'd0;
		strtag1	  <= 'd0;
		strtag2   <= 'd0;
		strtag3	  <= 'd0;
		rdata	  <= 'd0;
		count	  <= 4'd0;
		update_flag<= 1'd0;

	end
	else
	begin
		case(state)

			IDLE	:	begin
					
					addrlatch	<= addr_cpu;
					we0	  <= 1'd0;
					we1	  <= 1'd0;
					we2	  <= 1'd0;
					we3	  <= 1'd0;
					wet0	  <= 1'd0;
					wet1	  <= 1'd0;
					wet2	  <= 1'd0;
					wet3	  <= 1'd0;
					stall_cpu <= 1'd0;
					rd_mem	  <= 1'd0;
					wr_mem	  <= 1'd0;
//					rdata_byte<= 8'd0;
					wmem_byte <= 'd0;
					rmem_4byte<= 'd0;
					wdata	  <= 'd0;
					wtag0	  <= 'd0;
					wtag1	  <= 'd0;
					wtag2	  <= 'd0;
					wtag3	  <= 'd0;
					update_flag<= 1'd0;
					count	  <= 4'd0;

					if(rd_cpu)
					begin
						state	<= READ;
						rdwr	<= 1'd1;
					end
					else if(wr_cpu)
					begin
						state	<= WRITE;
						wdata_byte	<= data_cpu;
						rdwr	<= 1'd0;
					end
					else
						state	<= state;
					end

			READ	:	begin
					we0 <= 1'd0;
					we1 <= 1'd0;
					we2 <= 1'd0;
					we3 <= 1'd0;
					case(hit)
						1'd0:	begin
							strtag0	   <= rtag0;
							strtag1	   <= rtag1;
							strtag2	   <= rtag2;
							strtag3	   <= rtag3;
							strdata0   <= rdata0;
							strdata1   <= rdata1;
							strdata2   <= rdata2;
							strdata3   <= rdata3;
							stall_cpu  <= 1'd1;
							wet0 <= 1'd0;
							wet1 <= 1'd0;
							wet2 <= 1'd0;
							wet3 <= 1'd0;
							if(ready_mem)
								if(valid & dirty)
									state <= UPDATEMM;
								else
									state <= READMM;
							else
								state <= state;
							end

						1'd1:	begin
							state <= IDLE;
							wet0 <= 1'd1;
							wet1 <= 1'd1;
							wet2 <= 1'd1;
							wet3 <= 1'd1;
							stall_cpu  <= 1'd0;
								if(hit_w0)
								begin
									rdata_byte <= bytew0;
									if(uw0)
										wtag0 <= rtag0;
									else
										wtag0 <= {rtag0[13],1'd1,rtag0[11:0]};
									if(uw1)
										wtag1 <= {rtag1[13],1'd0,rtag1[11:0]};
									else
										wtag1 <= rtag1;
									if(uw2)
										wtag2 <= {rtag2[13],1'd0,rtag2[11:0]};
									else
										wtag2 <= rtag2;
									if(uw3)
										wtag3 <= {rtag3[13],1'd0,rtag3[11:0]};
									else
										wtag3 <= rtag3;
								end
								else if(hit_w1)
								begin
									rdata_byte <= bytew1;
									if(uw0)
										wtag0 <= {rtag0[13],1'd0,rtag0[11:0]};
									else
										wtag0 <= rtag0;
									if(uw1)
										wtag1 <= rtag1;
									else
										wtag1 <= {rtag1[13],1'd1,rtag1[11:0]};
									if(uw2)
										wtag2 <= {rtag2[13],1'd0,rtag2[11:0]};
									else
										wtag2 <= rtag2;
									if(uw3)
										wtag3 <= {rtag3[13],1'd0,rtag3[11:0]};
									else
										wtag3 <= rtag3;
								end
								else if(hit_w2)
								begin
									rdata_byte <= bytew2;
									if(uw0)
										wtag0 <= {rtag0[13],1'd0,rtag0[11:0]};
									else
										wtag0 <= rtag0;
									if(uw1)
										wtag1 <= {rtag1[13],1'd0,rtag1[11:0]};
									else
										wtag1 <= rtag1;
									if(uw2)
										wtag2 <= rtag2;
									else
										wtag2 <= {rtag2[13],1'd1,rtag2[11:0]};
									if(uw3)
										wtag3 <= {rtag3[13],1'd0,rtag3[11:0]};
									else
										wtag3 <= rtag3;
								end
								else
								begin
									rdata_byte <= bytew3;
									if(uw0)
										wtag0 <= {rtag0[13],1'd0,rtag0[11:0]};
									else
										wtag0 <= rtag0;
									if(uw1)
										wtag1 <= {rtag1[13],1'd0,rtag1[11:0]};
									else
										wtag1 <= rtag1;
									if(uw2)
										wtag2 <= {rtag2[13],1'd0,rtag2[11:0]};
									else
										wtag2 <= rtag2;
									if(uw3)
										wtag3 <= rtag3;
									else
										wtag3 <= {rtag3[13],1'd1,rtag3[11:0]};
								end
							end
					endcase
					end

			WRITE	:	begin
					
					case(hit)
						1'd0:	begin
							strtag0	   <= rtag0;
							strtag1	   <= rtag1;
							strtag2	   <= rtag2;
							strtag3	   <= rtag3;
							strdata0   <= rdata0;
							strdata1   <= rdata1;
							strdata2   <= rdata2;
							strdata3   <= rdata3;
							stall_cpu  <= 1'd1;
							if(ready_mem)
								if(valid & dirty)
									state <= UPDATEMM;
								else
									state <= READMM;
							else
								state <= state;

							end

						1'd1:	begin
							state <= IDLE;
							wet0 		<= 1'd1;
							wet1 		<= 1'd1;
							wet2 		<= 1'd1;
							wet3 		<= 1'd1;
							stall_cpu  <= 1'd0;
								if(hit_w0)
									begin
									we0		<= 1'd1;
									case(bytsel)
										2'd0: wdata <= {rdata0[127:32],wdata_byte};
										2'd1: wdata <= {rdata0[127:64],wdata_byte,rdata0[31:0]};
										2'd2: wdata <= {rdata0[127:96],wdata_byte,rdata0[63:0]};
										2'd3: wdata <= {wdata_byte,rdata0[95:0]};
									endcase
									
									if(uw0)
										wtag0 <= {rtag0[13:12],1'd1,rtag0[10:0]};
									else
										wtag0 <= {rtag0[13],1'd1,1'd1,rtag0[10:0]};
									if(uw1)
										wtag1 <= {rtag1[13],1'd0,rtag1[11:0]};
									else
										wtag1 <= rtag1;
									if(uw2)
										wtag2 <= {rtag2[13],1'd0,rtag2[11:0]};
									else
										wtag2 <= rtag2;
									if(uw3)
										wtag3 <= {rtag3[13],1'd0,rtag3[11:0]};
									else
										wtag3 <= rtag3;
									
									end
								


								else if(hit_w1)
									begin
									we1		<= 1'd1;
									case(bytsel)
										2'd0: wdata <= {rdata1[127:32],wdata_byte};
										2'd1: wdata <= {rdata1[127:64],wdata_byte,rdata1[31:0]};
										2'd2: wdata <= {rdata1[127:96],wdata_byte,rdata1[63:0]};
										2'd3: wdata <= {wdata_byte,rdata1[95:0]};
									endcase
									
									if(uw0)
										wtag0 <= {rtag0[13],1'd0,rtag0[11:0]};
									else
										wtag0 <= rtag0;
									if(uw1)
										wtag1 <= {rtag1[13:12],1'd1,rtag1[10:0]};
									else
										wtag1 <= {rtag1[13],1'd1,1'd1,rtag1[10:0]};
									if(uw2)
										wtag2 <= {rtag2[13],1'd0,rtag2[11:0]};
									else
										wtag2 <= rtag2;
									if(uw3)
										wtag3 <= {rtag3[13],1'd0,rtag3[11:0]};
									else
										wtag3 <= rtag3;
									
									end

								else if(hit_w2)
									begin
									we2		<= 1'd1;
									case(bytsel)
										2'd0: wdata <= {rdata2[127:32],wdata_byte};
										2'd1: wdata <= {rdata2[127:64],wdata_byte,rdata2[31:0]};
										2'd2: wdata <= {rdata2[127:96],wdata_byte,rdata2[63:0]};
										2'd3: wdata <= {wdata_byte,rdata2[95:0]};
									endcase
									
									if(uw0)
										wtag0 <= {rtag0[13],1'd0,rtag0[11:0]};
									else
										wtag0 <= rtag0;
									if(uw1)
										wtag1 <= {rtag1[13],1'd0,rtag1[11:0]};
									else
										wtag1 <= rtag1;
									if(uw2)
										wtag2 <= {rtag2[13:12],1'd1,rtag2[10:0]};
									else
										wtag2 <= {rtag2[13],1'd1,1'd1,rtag2[10:0]};
									if(uw3)
										wtag3 <= {rtag3[13],1'd0,rtag3[11:0]};
									else
										wtag3 <= rtag3;
									
									end	
								else
									begin
									we3		<= 1'd1;
									case(bytsel)
										2'd0: wdata <= {rdata2[127:32],wdata_byte};
										2'd1: wdata <= {rdata2[127:64],wdata_byte,rdata2[31:0]};
										2'd2: wdata <= {rdata2[127:96],wdata_byte,rdata2[63:0]};
										2'd3: wdata <= {wdata_byte,rdata2[95:0]};
									endcase
									
									if(uw0)
										wtag0 <= {rtag0[13],1'd0,rtag0[11:0]};
									else
										wtag0 <= rtag0;
									if(uw1)
										wtag1 <= {rtag1[13],1'd0,rtag1[11:0]};
									else
										wtag1 <= rtag1;
									if(uw2)
										wtag2 <= {rtag2[13],1'd0,rtag2[11:0]};
									else
										wtag2 <= rtag2;
									if(uw3)
										wtag3 <= {rtag3[13:12],1'd1,rtag3[10:0]};
									else
										wtag3 <= {rtag3[13],1'd1,1'd1,rtag3[10:0]};
									
									end	
							
							end
					endcase
					end
			
			READMM	:	begin
					addr_mem <= {addrlatch[15:2],2'd0};
					update_flag<= 1'd0;
						if(ready_mem)
						begin
							rd_mem <= 1'd1;
							state    <= WAITFORMM;
						end
						else
						begin
							rd_mem <= 1'd0;
							state  <= state;
						end
					end

			WAITFORMM :	begin
						if(ready_mem)
						begin
						//	if(rdwr)
						//	state <= UPDATECACHE;
						//	else
						//	begin
							if(update_flag)
							state <= READMM;
							else
							state <= UPDATECACHE;
						//	end

							rd_mem <= 1'd0;
							wr_mem <= 1'd0;
						end
						else
						begin
							if(!rdwr)
							begin
								wmem_byte <= wmem_4byte[31:0];
								wmem_4byte<= {32'd0,wmem_4byte[127:32]};
							end
							state <= state;
						end
							
					end

			UPDATEMM :	begin
						update_flag<= 1'd1;
						if(uw0)
						begin
							addr_mem <= {strtag0[10:0],addrlatch[4:2],2'd0};
							wmem_4byte <= strdata0;

						end
						
						if(uw1)
						begin
							addr_mem <= {strtag1[10:0],addrlatch[4:2],2'd0};
							wmem_4byte <= strdata1;

						end

						if(uw2)
						begin
							addr_mem <= {strtag2[10:0],addrlatch[4:2],2'd0};
							wmem_4byte <= strdata2;

						end
						else
						begin
							addr_mem <= {strtag3[10:0],addrlatch[4:2],2'd0};
							wmem_4byte <= strdata3;
						end
						
						if(ready_mem)
						begin
							wr_mem <= 1'd1;
							state    <= WAITFORMM;
						end
						else
						begin
							wr_mem <= 1'd0;
							state  <= state;
						end
					end

			UPDATECACHE:	begin
						update_flag<= 1'd0;
						
						if(count!=4'b1111)
						begin
							rmem_4byte <= {data_mem,rmem_4byte[127:32]};
							count <= {1'd1,count[3:1]};
						end
						else
						begin
							wdata <= rmem_4byte;
							state <= IDLE;
						/*	if(rdwr)
								state <= READ;
							else
								state <= WRITE; */
							if(uw0)
							begin
								wtag0 <= {strtag0[13],1'd0,strtag0[11:0]};
								wtag1 <= {1'd1,1'd0,1'd0,addrlatch[15:5]};
								wtag2 <= {1'd1,1'd0,1'd0,addrlatch[15:5]};
								wtag3 <= {1'd1,1'd0,1'd0,addrlatch[15:5]};
								we1   <= 1'd1;
								we2   <= 1'd1;
								we3   <= 1'd1;
								we0   <= 1'd0;
								wet0  <= 1'd1;
								wet1  <= 1'd1;
								wet2  <= 1'd1;
								wet3  <= 1'd1;

							end
							
							if(uw1)
							begin
								wtag0 <= {1'd1,1'd0,1'd0,addrlatch[15:5]};
								wtag1 <= {strtag1[13],1'd0,strtag1[11:0]};
								wtag2 <= {1'd1,1'd0,1'd0,addrlatch[15:5]};
								wtag3 <= {1'd1,1'd0,1'd0,addrlatch[15:5]};
								we1   <= 1'd0;
								we2   <= 1'd1;
								we3   <= 1'd1;
								we0   <= 1'd1;
								wet0  <= 1'd1;
								wet1  <= 1'd1;
								wet2  <= 1'd1;
								wet3  <= 1'd1;

							end

							if(uw2)
							begin
								wtag0 <= {1'd1,1'd0,1'd0,addrlatch[15:5]};
								wtag1 <= {1'd1,1'd0,1'd0,addrlatch[15:5]};
								wtag2 <= {strtag2[13],1'd0,strtag2[11:0]};
								wtag3 <= {1'd1,1'd0,1'd0,addrlatch[15:5]};
								we1   <= 1'd1;
								we2   <= 1'd0;
								we3   <= 1'd1;
								we0   <= 1'd1;
								wet0  <= 1'd1;
								wet1  <= 1'd1;
								wet2  <= 1'd1;
								wet3  <= 1'd1;

							end
							else
							begin
								wtag0 <= {1'd1,1'd0,1'd0,addrlatch[15:5]};
								wtag1 <= {1'd1,1'd0,1'd0,addrlatch[15:5]};
								wtag2 <= {1'd1,1'd0,1'd0,addrlatch[15:5]};
								wtag3 <= {strtag3[13],1'd0,strtag3[11:0]};
								we1   <= 1'd1;
								we2   <= 1'd1;
								we3   <= 1'd0;
								we0   <= 1'd1;
								wet0  <= 1'd1;
								wet1  <= 1'd1;
								wet2  <= 1'd1;
								wet3  <= 1'd1;

							end



						end
						
					end
					
			default:	begin
							addrlatch <= 'd0;
							addr_mem  <= 'd0;
							rd_mem	  <= 'd0;
							wr_mem	  <= 'd0;
							stall_cpu <= 'd0;
							state	  <= IDLE;
							rdata_byte<= 'd0;
							wdata_byte<= 'd0;
							wmem_byte <= 'd0;
							rmem_4byte<= 'd0;
							wmem_4byte<= 'd0;
							wdata	  <= 'd0;
							wtag0	  <= 'd0;
							wtag1	  <= 'd0;
							wtag2	  <= 'd0;
							wtag3	  <= 'd0;
							we0	      <= 1'd0;
							we1 	  <= 1'd0;
							we2	      <= 1'd0;
							we3 	  <= 1'd0;
							wet0	  <= 1'd0;
							wet1	  <= 1'd0;
							wet2	  <= 1'd0;
							wet3	  <= 1'd0;
							rdwr	  <= 1'd1;
							strdata0  <= 'd0;
							strdata1  <= 'd0;
							strdata2  <= 'd0;
							strdata3  <= 'd0;
							strtag0   <= 'd0;
							strtag1	  <= 'd0;
							strtag2   <= 'd0;
							strtag3	  <= 'd0;
							rdata	  <= 'd0;
							count	  <= 4'd0;

					end
		endcase
	end
end

// Instantiation of Tag RAM for Way 0

defparam tr0.AWIDTH = 3;
defparam tr0.DWIDTH = VALIDBIT+USEDBIT+DIRTYBIT+TAGWIDTH; 

ram_sync_read_t0 tr0 (
			.clock(clock),
			.addr(index),
			.din(wtag0),
			.we(wet0),
			.dout(rtag0)
			);

// Instantiation of Tag RAM for Way 1

defparam tr1.AWIDTH = 3;
defparam tr1.DWIDTH = VALIDBIT+USEDBIT+DIRTYBIT+TAGWIDTH;

ram_sync_read_t1 tr1 (
			.clock(clock),
			.addr(index),
			.din(wtag1),
			.we(wet1),
			.dout(rtag1)
			);
// Instantiation of Tag RAM for Way 2

defparam tr2.AWIDTH = 3;
defparam tr2.DWIDTH = VALIDBIT+USEDBIT+DIRTYBIT+TAGWIDTH; 

ram_sync_read_t2 tr2 (
			.clock(clock),
			.addr(index),
			.din(wtag2),
			.we(wet2),
			.dout(rtag2)
			);

// Instantiation of Tag RAM for Way 3

defparam tr3.AWIDTH = 3;
defparam tr3.DWIDTH = VALIDBIT+USEDBIT+DIRTYBIT+TAGWIDTH;

ram_sync_read_t3 tr3 (
			.clock(clock),
			.addr(index),
			.din(wtag3),
			.we(wet3),
			.dout(rtag3)
			);

// Instantiation Data RAM for Way 0

defparam dr0.AWIDTH = 3;
defparam dr0.DWIDTH = DWIDTH*BLOCKSIZE;

ram_sync_read_d0 dr0 (
			.clock(clock),
			.addr(index),
			.din(wdata),
			.we(we0),
			.dout(rdata0)
			);

// Instantiation Data RAM for Way 1

defparam dr1.AWIDTH = 3;
defparam dr1.DWIDTH = DWIDTH*BLOCKSIZE;

ram_sync_read_d1 dr1 (
			.clock(clock),
			.addr(index),
			.din(wdata),
			.we(we1),
			.dout(rdata1)
			);

// Instantiation Data RAM for Way 2

defparam dr2.AWIDTH = 3;
defparam dr2.DWIDTH = DWIDTH*BLOCKSIZE;

ram_sync_read_d2 dr2 (
			.clock(clock),
			.addr(index),
			.din(wdata),
			.we(we2),
			.dout(rdata2)
			);

// Instantiation Data RAM for Way 3

defparam dr3.AWIDTH = 3;
defparam dr3.DWIDTH = DWIDTH*BLOCKSIZE;

ram_sync_read_d3 dr3 (
			.clock(clock),
			.addr(index),
			.din(wdata),
			.we(we3),
			.dout(rdata3)
			);

// END OF MODULE
endmodule
