`timescale 1ns / 1ps

module instr_decode(
input clk_2M,INTR,reset,
input exe_start,imm_done,alu_done,
output reg exe_end,b_d,st_ld,sta,lxi,shld_lhld,
output reg [1:0] inx_dcx,lxi_add,
input [7:0] IR,
output reg [2:0] reg_operation, 
output reg [3:0] destination,source,
output reg addl_en,Read,Write,ALU_en,imm_op,ALU_mem,inr_dcr,dad,
output reg [3:0]ALU_ctrl 
    ); 

reg [3:0] IR_l;
reg [3:0] IR_h;  

reg ID; // interrupt disable ff
reg IE; // interrupt enable ff
reg hlt; // halt ff

reg [2:0]n_case=0; 
reg step2; 
reg [1:0]waste_t=2'd0;

always@(posedge clk_2M) begin 
IR_l<=IR[3:0];
IR_h<=IR[7:4]; 
if(~exe_start) begin 
       {ALU_en,ALU_mem,b_d,st_ld,sta,lxi,inr_dcr,dad}<=8'd0;
       {inx_dcx,lxi_add}<=4'd0;
 end 
if(exe_start) begin 
case(IR_h) 
4'b0100,4'b0101,4'b0110: begin //single t state or memory read.
        if(IR_h == 4)begin 
        if(IR_l <=7) destination <=4'd0; 
        else destination <=4'd1; end 
        
        else if(IR_h == 5)begin 
        if(IR_l <=7) destination <=4'd2; 
        else destination <=4'd3; end 
        
        else if(IR_h == 6)begin 
        if(IR_l <=7) destination <=4'd4; 
        else destination <=4'd5; end  
         
        if(IR_l == 4'b0110 |IR_l ==4'b1110)begin //mov r,m
             case(n_case)  
             2'b00: begin 
                    addl_en <=1'd1; 
                    Read <=1'd0; 
                    Write <=1'd0; 
                    n_case <=2'b01;   
                    end 
             2'b01: begin 
                    addl_en <=1'd0; 
                    Read <=1'd1; 
                    Write <=1'd0;
                    n_case <=2'b10;   
                    end 
             2'b10: begin 
                    reg_operation <=3'b001;  
                    addl_en <=1'd0; 
                    Read <=1'd0; 
                    Write <=1'd0;  
                    n_case <= 2'd0;    
                    exe_end <=1'd1; 
                    end 
             endcase 
        end  
        
        else begin    
        reg_operation <=3'd0; 
        source <={1'b0,{IR_l[2:0]}};   
        exe_end <=1'd1; end  
        
        end  
        
4'b0111: begin  // 1st half loading register to memory(memory write) , 2nd half,register to acc(acc write)
         source <={1'b0,{IR_l[2:0]}}; 

         if(IR_l == 4'b0110) begin   //hlt instruction.
          case(n_case) 
            2'b00: hlt <=1'd1;  //4th t state
            2'b01: hlt <=1'd1; //5th t state 
            2'b10: begin 
                   if(ID==1) begin  //when interrupt disabled. 
                         if(reset) begin 
                         exe_end <=1'd1;
                         hlt<=1'd0; 
                         n_case <=2'b00;  end 
                         else begin 
                         exe_end <=1'd0;                     
                         hlt <=1'd1; 
                         n_case <=2'b10; end end 

                   else if (IE==1 && ID==0) begin  
                        if(INTR||reset) begin 
                         exe_end <=1'd1;
                         hlt<=1'd0; 
                         n_case <=2'b00;  end 
                         else begin 
                         exe_end <=1'd0; 
                         hlt <=1'd1;
                         n_case <=2'b10; end
                   end  
                   end 
          endcase
         end  

         else if(IR_l == 4'b1110) begin   //mov a,m 
         destination <= 4'b0111;
          case(n_case)  
             2'b00: begin 
                    addl_en <=1'd1; 
                    Read <=1'd0; 
                    Write <=1'd0; 
                    n_case <=2'b01;   
                    end 
             2'b01: begin 
                    addl_en <=1'd0; 
                    Read <=1'd1; 
                    Write <=1'd0;
                    n_case <=2'b10;   
                    end 
             2'b10: begin 
                    reg_operation <=3'b001;  
                    addl_en <=1'd0; 
                    Read <=1'd0; 
                    Write <=1'd0;  
                    n_case <= 2'd0;    
                    exe_end <=1'd1; 
                    end 
             endcase 
         end  

         else begin  
         if(IR_l <=7)begin // register to memory mov m,r
            case(n_case)  
             2'b00: begin
                    addl_en <=1'd1; 
                    Read <=1'd0; 
                    Write <=1'd0;  
                    n_case <=2'b00;
                    end 
             2'b01: begin 
                    addl_en <=1'd0; 
                    reg_operation <=3'b010;
                    Read <=1'd0; 
                    Write <=1'd0; 
                    n_case <=2'b10;  
                    end 
             2'b10: begin   
                    addl_en <=1'd0; 
                    Read <=1'd0; 
                    Write <=1'd1; 
                    n_case <= 2'd0;    
                    exe_end <=1'd1; 
                    end 
             endcase end 
             else begin //ir_l >7 , register to a, single t state. mov a,r
              reg_operation <=3'd0; 
              destination <= 4'b0111; 
              exe_end <=1'd1; end  
         end 
   end   

4'b1000,4'b1001,4'b1010,4'b1011: begin   // here i have used alu_done for exe_end 

       if(IR_h == 4'h8) ALU_ctrl <= (IR_l>7)?4'd1:4'd0; 
       else if(IR_h == 4'h9) ALU_ctrl <= (IR_l>7)?4'd3:4'd2; 
       else if(IR_h == 4'hA) ALU_ctrl <= (IR_l>7)?4'd5:4'd4; 
       else if(IR_h == 4'hB) ALU_ctrl <= (IR_l>7)?4'd7:4'd6;

       if(IR_l[2:0] == 3'b110) begin  //for memory related arithmetic operations.
       ALU_mem <=1'd1;
        case(n_case)
         2'b00: begin
                    addl_en <=1'd1; 
                    Read <=1'd0; 
                    Write <=1'd0; 
                    n_case <=2'b01;   
                    end 
             2'b01: begin 
                    addl_en <=1'd0; 
                    Read <=1'd1; 
                    Write <=1'd0;
                    n_case <=2'b10;      
                    end 
             2'b10: begin 
                    addl_en <=1'd0; 
                    ALU_en <=1'd1;
                    Read <=1'd0; 
                    Write <=1'd0; 
                    n_case <= 2'b00;
                    exe_end <=1'd1; 
                     end      
              endcase 
       end 
       else begin 
       ALU_en <= 1'd1; 
       source <={1'b0,{IR_l[2:0]}}; 
       exe_end <=1'd1;  end 
       
  end  

4'b1100,4'b1101,4'b1110,4'b1111: begin //arithmetic with immediate.//have to add other instructions also. 

    if(IR_l[2:0] == 3'b110) begin  //immediate.
     imm_op <=1'd1;
       if(IR_h == 4'd12) ALU_ctrl <= (IR_l>7)?4'd1:4'd0; 
       else if(IR_h == 4'd13) ALU_ctrl <= (IR_l>7)?4'd3:4'd2; 
       else if(IR_h == 4'hE) ALU_ctrl <= (IR_l>7)?4'd5:4'd4; 
       else if(IR_h == 4'hF) ALU_ctrl <= (IR_l>7)?4'd7:4'd6;
     if(imm_done) begin 
       ALU_en <=1'd1; 
       ALU_mem <=1'd1;
       imm_op <=1'd0;
       exe_end <=1'd1; end 
    end  
   
   if(IR_h == 4'b1111 && IR_l==4'b0011) begin  //interrupt disable,
   ID<=1; 
   exe_end <=1; end   

   if(IR_h == 4'b1111 && IR_l==4'b1011) begin  //interrupt disable,
   IE<=1; 
   exe_end <=1; end  


   end 


4'b0000,4'b0001,4'b0010,4'b0011: begin  

if(IR_l[2:0] == 3'b100|IR_l[2:0] == 3'b101) begin  //inr and dcr instructions.
     if(IR_l[2:0] == 3'b100) ALU_ctrl<=0 ;
     if(IR_l[2:0] == 3'b101) ALU_ctrl<=2 ; 

     if(IR_h<=4'b0010) source <= IR_h*2+IR_l[3];
     if(IR_h==4'b0011&&IR_l[3]) source <= 4'b0111; 
    
     if(IR_h==4'b0110&&IR_l[3]==0) begin  // inr m and dcr m
       if(alu_done) begin 
       inr_dcr<=0;
       ALU_mem <=0;
        case(n_case)  
             2'b00: begin  
                    addl_en <=1'd0; 
                    reg_operation <=3'b101;
                    Read <=1'd0; 
                    Write <=1'd0; 
                    n_case <=2'b10;  
                    end 
             2'b01: begin   
                    addl_en <=1'd0; 
                    Read <=1'd0; 
                    Write <=1'd1; 
                    n_case <= 2'b10;    
                    end   
              2'b10: begin 
                     Write <=1'd0; 
                     n_case <= 2'd0;    
                     exe_end <=1'd1; 
                     end 
             endcase
        end 

       else begin
		 ALU_mem <=1;
       inr_dcr <=1;  
		 case(n_case)
       
             2'b00: begin
                    addl_en <=1'd1; 
                    Read <=1'd0; 
                    Write <=1'd0; 
                    n_case <=2'b01;   
                    end 
             2'b01: begin 
                    addl_en <=1'd0; 
                    Read <=1'd1; 
                    Write <=1'd0;
                    n_case <=2'b10;      
                    end 
             2'b10: begin 
                    addl_en <=1'd0; 
                    ALU_en <=1'd1;
                    Read <=1'd0; 
                    Write <=1'd0; 
                    n_case <= 2'd00; 
                     end      
       endcase  end 
     end 
     
     else begin 
     ALU_en <=1;
     inr_dcr<=1; 
     if(alu_done) begin 
       exe_end <=1; 
       inr_dcr<=0;
       ALU_mem <=0;
        end end 

     end  

if(IR_l[2:0]==3'b111) begin  // flag and accumulator manipulation instructions 
   ALU_en <=1;
   exe_end <=1'd1;
   case(IR_h)  
    4'd0: begin 
          if(IR_l[3]) ALU_ctrl<= 4'd11; 
          else ALU_ctrl <= 4'd10;
    end 
    4'd1: begin 
        if(IR_l[3]) ALU_ctrl<= 4'd9; 
        else ALU_ctrl <= 4'd8;
    end 
    4'd2: begin
        if(IR_l[3]) ALU_ctrl<= 4'd15; 
        else ALU_ctrl <= 4'd12;
    end
    4'd3: begin
        if(IR_l[3]) ALU_ctrl<= 4'd13; 
        else ALU_ctrl <= 4'd14;
    end
   endcase 
   end  

   if(IR_l[2:0] == 3'b110) begin  // move immidiate to register. 

   if(IR_h == 4'b0011 && ~IR_l[3]) begin  // mvi m, data 
   imm_op <=1; 
   if(imm_done) begin //write data.  
   imm_op <=0; 
   case(n_case)  
             2'b00: begin 
                    addl_en <=1'd1; 
                    Read <=1'd0; 
                    Write <=1'd0;  
                    reg_operation <=3'b100;
                    n_case <=2'b00;
                    end 
             2'b01: begin 
                    addl_en <=1'd0; 
                    Read <=1'd0; 
                    Write <=1'd1; 
                    n_case <=2'b10;  
                    end 
             2'b10: begin   
                    addl_en <=1'd0; 
                    Read <=1'd0; 
                    Write <=1'd0; 
                    n_case <= 2'd0;    
                    exe_end <=1'd1; 
                    end 
             endcase
   end 
end 
   else begin  
    if(IR_h<=4'b0010) destination <= IR_h<<IR_h+IR_l[3]; 
    else if(IR_h==4'b0011&&IR_l[3]) destination <= 4'b0111;  //accumulator. 

    imm_op <=1; 
    if(imm_done) begin 
       reg_operation <=3'b001;
       imm_op <=0; 
       exe_end <=1; end 
     end 
   end  

   if(IR_l[2:0] == 3'b010) begin //store and load from memory to acc or register(indirect addressing) 
   b_d <= IR_h[0]?1:0; //b_d is 1 for stax and 0 for ldax. 

     if(IR_h<=4'b0010 && IR_l[3]) begin //ldax 
     case(n_case)  
       2'b00: begin 
              st_ld<=1; 
              addl_en <=1'd1;
              Read <=1'd0; 
              n_case <=2'b01;   
              end
       2'b01: begin
              st_ld<=0; 
              addl_en <=1'd0; 
              Read <=1'b1; 
              n_case <=2'b10;  
              end
       2'b10: begin 
              st_ld<=0; 
              addl_en <=1'd0; 
              Read <=1'b0; 
              reg_operation <=3'b110; 
              n_case <= 2'd0; 
              exe_end <=1'd1; 
              end
             endcase 
   end 
   else if(IR_h<=4'b0010 && ~IR_l[3]) begin //stax   
        case(n_case)  
         2'b00: begin 
              st_ld<=1; 
              addl_en <=1'd1;
              Write <=1'd0; 
              reg_operation <=3'b011;
              n_case <=2'b01;   
              end
       2'b01: begin
              st_ld<=0; 
              addl_en <=1'd0; 
              Write <=1'd1; 
              n_case <=2'b10;  
              end
       2'b10: begin 
              st_ld<=0; 
              addl_en <=1'd0; 
              Write <=1'd0;  
              n_case <= 2'd0; 
              exe_end <=1'd1; 
              end
        endcase 
   end 
    
   if(IR_h == 4'b0011 && IR_l[3]) begin // LDA  
   if(~step2) begin  
   case(n_case)  
       2'b00:begin 
             imm_op <=1; 
             n_case <=2'b01; end 
       2'b01: begin 
              if(~imm_done) n_case <=2'b01;  
              else begin  
              imm_op <=0;
              reg_operation <=3'b001;
              destination <= 4'b1010; //z (lsb)
              n_case <=2'b10; end
              end
       2'b10: begin 
              imm_op <=1;
              n_case <=2'b11; end
       2'b11: begin 
              if(~imm_done) n_case <=2'b11;  
              else begin 
              imm_op <=0;
              reg_operation <=3'b001;
              destination <= 4'b0110; //w (msb)
              n_case <=2'b00; 
              step2<=1; end 
       end  
        endcase 
   end 
       if(step2) begin
       sta<=1;
       case(n_case)  
       2'b00: begin 
             addl_en <=1'd1; 
             Read <=1'd0; 
             Write <=1'd0;  
             n_case <=2'b01;
             end
       2'b01: begin 
               addl_en <=1'd0; 
               Read <=1'd1; 
               Write <=1'd0;
               n_case <=2'b10;end
       2'b10:  begin 
               exe_end <=1; 
               n_case <=2'b00;
               reg_operation <=3'b001;
               destination <= 4'b0111; //accumulator.
               step2<=0; 
               sta <=0;
               end 
       endcase
       end 
   end  

   if(IR_h == 4'b0011 && ~IR_l[3]) begin // STA 
   if(~step2) begin  
   case(n_case)  
       2'b00:begin 
             imm_op <=1; 
             n_case <=2'b01; end 
       2'b01: begin 
              if(~imm_done) n_case <=2'b01;  
              else begin  
              imm_op <=0;
              reg_operation <=3'b001;
              destination <= 4'b1010; //z (lsb)
              n_case <=2'b10; end
              end
       2'b10: begin 
              imm_op <=1;
              n_case <=2'b11; end
       2'b11: begin 
              if(~imm_done) n_case <=2'b11;  
              else begin  
              imm_op <=0;
              reg_operation <=3'b001;
              destination <= 4'b0110; //w (msb)
              n_case <=2'b00; 
              step2<=1; end 
       end  
        endcase 
   end 
       if(step2) begin
              sta <=1;
       case(n_case)  
       2'b00: begin 
             reg_operation <=3'b011;  
             addl_en <=1'd1; 
             Read <=1'd0; 
             Write <=1'd0;  
             n_case <=2'b01;
             end
       2'b01: begin 
               addl_en <=1'd0; 
               Read <=1'd0; 
               Write <=1'd1;
               exe_end <=1; 
               step2<=0; 
               sta <=0;
               n_case <=2'b00;  end 
       endcase
       end 
   end  

   if(IR_l[2:0] ==3'b011) begin  //INX and DCX 
    case(n_case)   
       2'b00: begin 
              inx_dcx <=IR_l[3]?2'd2:2'd1; 
             if(IR_h<=4'b0010) begin
               source <= IR_h<<IR_h; 
               destination <= IR_h<<IR_h +4'd1; end 
                   else begin source <=4'b1000; 
                destination <=4'b1001; end end  
       2'b01: begin 
              inx_dcx <=0; 
              exe_end <=1;
              n_case <=2'b00;
       end 
    endcase
end 
   end     

   if(IR_l == 4'b1001) begin // DAD  
   case(n_case)
      2'b00: begin  
        ALU_en <=1;
        ALU_ctrl <= 4'd0;  
        dad <=1; 
        if(IR_h<=4'b0010) destination <= IR_h<<IR_h;  
        else destination <= 4'b1000;
        source <= 4'b0101; //l register.
        n_case <=2'b01; 
      end 
      2'b01: begin  
              ALU_en <=0; 
              reg_operation <=3'b111;
              n_case <=2'b01; 
      end 
      2'b10: begin  
            ALU_en <=1;  
            ALU_ctrl <= 4'd1; 
            if(IR_h<=4'b0010) destination <= IR_h<<IR_h+4'd1;
            else destination <= 4'b1001;
            source <= 4'b0110; //h register. 
            n_case <=2'b11;
       end
      2'b11: begin  
              ALU_en <=0; 
              dad <=0;
              reg_operation <=3'b111;
              if(waste_t == 2) begin 
              n_case <=2'b00; 
              exe_end <=1; 
              waste_t <=0;
              end 
              else begin waste_t <= waste_t +2'd1; 
              n_case <=2'b11; end 
       end
   endcase 
   end  

if(IR_l[2:0]==3'b000) begin   //nop
       exe_end <=1;
end  

if(IR_l==4'b0001) begin  //lxi 
  imm_op <=1; 
  reg_operation <=3'b001;
  lxi <= 1; 

  if(lxi_add == 1)  begin 
       if(IR_h<=4'b0010) destination <= IR_h<<IR_h; 
       else  destination <=4'b1000;  end
  else if(lxi_add == 2)  begin 
       if(IR_h<=4'b0010) destination <= IR_h<<IR_h+4'd1; 
       else  destination <=4'b1001;  end

  if(imm_done) begin 
    imm_op <=0; 
    lxi <=0; 
    exe_end <=1; end

end  

if(IR_l==4'b0010 && IR_h==4'd2) begin  //shld  
if(~step2) begin
case(n_case)  
       2'b00:begin 
             imm_op <=1; 
             n_case <=2'b01; end 
       2'b01: begin 
              if(~imm_done) n_case <=2'b01;  
              else begin  
              imm_op <=0;
              reg_operation <=3'b001;
              destination <= 4'b1010; //z (lsb)
              n_case <=2'b10; end
              end
       2'b10: begin 
              imm_op <=1;
              n_case <=2'b11; end
       2'b11: begin 
              if(~imm_done) n_case <=2'b11;  
              else begin  
              imm_op <=0;
              reg_operation <=3'b001;
              destination <= 4'b0110; //w (msb)
              n_case <=2'b00; 
              step2<=1; end 
       end  
        endcase 
end 
if(step2) begin

case(n_case)
       2'b00: begin 
             addl_en <=1'd1;
             sta<=1;          // allows mem_add to be wz. 
       end 
       2'b01: begin 
               addl_en <=1'd1;
               Read<=1; 
               shld_lhld =1;  // mem_add changed. 
       end 
       2'b10: begin 
               addl_en <=1'd0;
               Read<=1; 
               reg_operation <=3'b001;
               destination<=4'b0101; //l register.
               shld_lhld =0;  
       end 
       2'b11: begin 
              addl_en <=1'd0;
              Read<=0; 
              reg_operation <=3'b001;
              destination<=4'b0110; //h register.
              n_case <=2'b00; 
              step2<=0; 
              exe_end <=1; 
       end 
endcase 

end 
end  

if(IR_l==4'b1010 && IR_h==4'd2) begin  //lhld  
if(~step2) begin
case(n_case)  
       2'b00:begin 
             imm_op <=1; 
             n_case <=2'b01; end 
       2'b01: begin 
              if(~imm_done) n_case <=2'b01;  
              else begin  
              imm_op <=0;
              reg_operation <=3'b001;
              destination <= 4'b1010; //z (lsb)
              n_case <=2'b10; end
              end
       2'b10: begin 
              imm_op <=1;
              n_case <=2'b11; end
       2'b11: begin 
              if(~imm_done) n_case <=2'b11;  
              else begin  
              imm_op <=0;
              reg_operation <=3'b001;
              destination <= 4'b0110; //w (msb)
              n_case <=2'b00; 
              step2<=1; end 
       end  
        endcase 
end 
if(step2) begin

case(n_case)
       2'b00: begin 
             addl_en <=1'd1;
             reg_operation <=3'b010;
             source <=4'b0101; //l register.
             sta<=1;          // allows mem_add to be wz. 
       end 
       2'b01: begin 
               addl_en <=1'd1;
               Write<=1; 
               reg_operation <=3'b010;
               source <=4'b0110; //h register.
               shld_lhld <=1;  // mem_add changed. 
       end 
       2'b10: begin 
               addl_en <=1'd0;
               Write<=1; 
               shld_lhld <=0;  
       end 
       2'b11: begin 
              addl_en <=1'd0;
              Read<=0; 
              n_case <=2'b00; 
              step2<=0; 
              exe_end <=1; 
       end 
endcase 

end 
end 
end 

endcase
end 
end 
endmodule
