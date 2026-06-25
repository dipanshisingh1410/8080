`timescale 1ns / 1ps
module reg_array(
input clk_2M,
input [2:0] reg_operation,destination,source,
input [7:0]data,
output reg [7:0] data_write,
output reg [15:0] mem_add,
input ALU_en,ALU_mem,inr_dcr,b_d,st_ld,sta,dad,shld_lhld,
input [1:0] inx_dcx,
input [7:0] ALU_op,
output reg [7:0] ALU_ip1,ALU_ip2
    ); 

reg alu_temp; 
reg [3:0] GPR [15:0]; 
// 0000 -- B 
// 0001 -- C 
// 0010 -- D 
// 0011 -- E 
// 0100 -- H 
// 0101 -- L 
// 0110 -- W
// 0111 -- Acc  
// 1000 -- SP{lSB}
// 1001 -- SP{mSB}
// 1010 -- Z 

//asynchrounous read. 
always@(*)begin  
if(st_ld) begin 
    if(b_d)
    mem_add<={GPR[0],GPR[1]};      //bc
    else mem_add<={GPR[2],GPR[3]}; //de
end 
else if (sta) mem_add<={GPR[6],GPR[10]};  //wz
else if(shld_lhld) mem_add<={GPR[4],GPR[5]}+16'd1; //HL+1 for LHLD and HL for SHLD
else mem_add<={GPR[4],GPR[5]};  //default mem_address is HL pair

if(ALU_en) begin  
    if(ALU_mem && inr_dcr) ALU_ip1 <= data; 
    else if(inr_dcr||dad) ALU_ip1 <= GPR[source]; 
    else ALU_ip1 <= GPR[4'b0111];  //acc 
    
    if(dad) ALU_ip2 <= GPR[destination];
    else if(inr_dcr) ALU_ip2 <= 8'd1; 
    else ALU_ip2 <= GPR[source]; 
end  
end 
//writing data synchronous
always@(posedge clk_2M) begin

case(reg_operation)
3'b000: GPR[destination] <= GPR[source]; 
3'b001: GPR[destination] <= data;  
3'b010: data_write <= GPR[source]; 
3'b011: data_write <= GPR[4'b0111]; 
3'b100: data_write <= data; 
3'b101: data_write <=GPR[4'b0110];  
3'b110: GPR[4'b0111] <= data;  
3'b111: GPR[source] <= ALU_op;
endcase 

if(~dad)begin 
    if(inr_dcr && ~ALU_mem) GPR[source] <= ALU_op;
    if(ALU_mem && inr_dcr) GPR[4'b0110] <= ALU_op; //W (temp) gets the result
    else GPR[4'b0111] <= ALU_op; end 

if(inx_dcx==2'd1)   
    {GPR[source],GPR[destination]} <= {GPR[source],GPR[destination]} + 16'd1; 
if(inx_dcx==2'd2)   
    {GPR[source],GPR[destination]} <= {GPR[source],GPR[destination]} - 16'd1;  
end 
endmodule
