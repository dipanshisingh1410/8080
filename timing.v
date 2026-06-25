`timescale 1ns / 1ps

module timing(
input clk_2M,
output reg DBIN,
output reg IR_load,Write,
input exe_end,imm_op,lxi,
output reg pc_inc,
output reg exe_start,imm_done,sync,
output reg [1:0] lxi_add
    ); 

reg [1:0] state=2'b00; 
reg n_case;
reg n_case2;
reg temp;
    
always@(posedge clk_2M) begin   
case(state) 
2'b00: begin  
       lxi_add <=2'b00; 
       sync <=1'd1;
       imm_done <=1'd0;
       DBIN <=1'd1; 
       IR_load<=1'd0; 
       pc_inc <=1'd0; 
       state <= 2'b01; 
       end 
2'b01: begin 
       sync <=1'd0;
       DBIN <=1'd1; 
       IR_load<=1'd1; 
       pc_inc <=1'd0; 
       state <= 2'b10; end 
2'b10: begin 
       DBIN <=1'd0; 
       IR_load<=1'd1; 
       pc_inc <=1'd1; 
       state <= 2'b11;
       exe_start <=1'd1; end
2'b11: begin  
       DBIN <=1'd0; 
       IR_load<=1'd0; 
       pc_inc <=1'd0;  
       if(imm_op) begin 
          case(n_case)
               1'b0: begin
                     DBIN <=1;
                     pc_inc <=1'd1; end 
               1'b1: begin
                     DBIN <=1;    
                     n_case <=1'b0;                
                     pc_inc <=1'd0;
                     if(~lxi||(lxi && lxi_add==2'b01)) imm_done <=1'd1;
                     if(lxi) lxi_add <= lxi_add + 2'b1; 
               end
          endcase 
       end  
       if(exe_end) begin state<=2'b00; exe_start <=1'd0; Write<=1'd0; end 
       else state <=2'b11; 
       end  
endcase 
end 


endmodule
