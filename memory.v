`timescale 1ns / 1ps

module memory(
input clk_2M,   
input [15:0] add_latch, 
input DBIN,Read,Write,addl_en,
output reg [7:0]data,
input [7:0] data_write
    );  
    
reg [16'h1111:0] mem [7:0] ; 

always@(posedge clk_2M) begin 
if(DBIN|Read)
data <= mem[add_latch] ;  
if(Write)
mem[add_latch] <=data_write; 
end     

endmodule
