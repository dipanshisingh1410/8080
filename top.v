`timescale 1ns / 1ps

module top(
    input clk_2M,
    
    output SYNC,
    output dbin,
    output WR_n,
    output WAIT,
    output HLDA,
    output [7:0] ALU_op,
	 
    input READY,
    input HOLD,
    input INTR,
    input reset
    ); 

reg [15:0] PC; 
wire [15:0] add_latch,mem_add;
wire [7:0] data;
wire [7:0] data_write; 
wire pc_inc;  

wire [7:0] IR;  

wire DBIN,IR_load,exe_end,exe_start,addl_en,Read,Write,ALU_en,imm_op,ALU_mem,alu_done,imm_done,inr_dcr,b_d,st_ld,dad,lxi,sta,shld_lhld; 
wire [1:0] inx_dcx,lxi_add; 
wire [2:0]reg_operation; 
wire [3:0] destination,source;  
wire [3:0] ALU_ctrl; 
//wire [7:0] ALU_op; 
wire [7:0] ALU_ip1,ALU_ip2; 

wire sync;  

initial begin
PC <= 16'h0000;
end 

always@(posedge clk_2M)begin 
if(reset) 
PC <= 16'h0000; 
else if(pc_inc)begin 
PC<=PC+16'd1;   
end 
end

timing timing(clk_2M,DBIN,IR_load,exe_end,Write,imm_op,lxi,pc_inc,exe_start,imm_done,sync,lxi_add); 
fetch fetch(clk_2M,DBIN,addl_en,IR_load,PC,mem_add,add_latch,data,IR); 
instr_decode instr_decode(clk_2M,INTR,reset,exe_start,imm_done,alu_done,exe_end,b_d,st_ld,sta,lxi,shld_lhld,inx_dcx,lxi_add,IR,reg_operation, destination,source,addl_en,Read,Write,ALU_en,imm_op,ALU_mem,inr_dcr,dad,ALU_ctrl ); 
alu alu(ALU_en,inr_dcr,dad,ALU_ctrl,ALU_op,ALU_ip1,ALU_ip2,alu_done);  

reg_array reg_array(clk_2M,reg_operation,destination,source,data,data_write,mem_add,ALU_en,ALU_mem,inr_dcr,b_d,st_ld,sta,dad,shld_lhld,inx_dcx,ALU_op,ALU_ip1,ALU_ip2); 
memory memory(clk_2M,add_latch,DBIN,Read,Write,addl_en,data,data_write);  

assign dbin = DBIN; 
assign SYNC = sync; 

endmodule
