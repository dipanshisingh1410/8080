`timescale 1ns / 1ps
module fetch(
input clk_2M,
input DBIN,addl_en,
input IR_load,
input [15:0]PC,mem_add,
output reg [15:0] add_latch, 
input [7:0] data,
output reg [7:0] IR
); 

always@(posedge clk_2M) begin 
if(DBIN) add_latch <= PC;  
if(addl_en) add_latch <= mem_add; 
if(IR_load) IR <= data; 
end 
endmodule 