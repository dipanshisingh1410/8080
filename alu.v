`timescale 1ns / 1ps

module alu(
input ALU_en, inr_dcr, dad,
input [3:0] ALU_ctrl,
output reg [7:0] ALU_op,
input [7:0] ALU_ip1, ALU_ip2,
output reg alu_done
);   

// Flag : {Sign, Zero, 0, AuxCarry, 0, Parity, 1, Carry}
reg [7:0] Flag = 8'b00000010; 
reg [8:0] temp;   

always @(*) begin  
// Default values to prevent latches
alu_done = 1'b0;
if (ALU_en) begin 
 case(ALU_ctrl) 

         4'd0: begin    // ADD
                    temp = ALU_ip1 + ALU_ip2;
                    if (inr_dcr) begin  
                        ALU_op = temp[7:0];
                    end 
                    else {Flag[0], ALU_op} = temp; 
                    
                    if (~dad) begin 
                        Flag[7] = temp[7];
                        Flag[6] = (temp[7:0] == 8'b0); // Zero Flag
                        Flag[4] = ((ALU_ip1[3:0] + ALU_ip2[3:0]) > 4'b1111); // AC
                        Flag[2] = ~^temp[7:0]; // Parity (Even)
                    end 
                    alu_done = 1'b1;
                end 

                4'd1: begin    // ADC (Add with Carry)
                    temp = ALU_ip1 + ALU_ip2 + {8'd0, Flag[0]}; 
                    {Flag[0], ALU_op} = temp; 
                    if (~dad) begin
                        Flag[7] = temp[7];
                        Flag[6] = (temp[7:0] == 8'b0);
                        Flag[4] = ((ALU_ip1[3:0] + ALU_ip2[3:0] + {3'b000, Flag[0]}) > 4'b1111);
                        Flag[2] = ~^temp[7:0];
                    end 
                    alu_done = 1'b1;
                end  

                4'd2: begin // SUB
                    temp = ALU_ip1 - ALU_ip2; 
                    if (inr_dcr) begin 
                        ALU_op = temp[7:0];
                    end 
                    else {Flag[0], ALU_op} = temp;
                    
                    Flag[7] = temp[7];
                    Flag[6] = (temp[7:0] == 8'b0);
                    Flag[4] = ((ALU_ip1[3:0] - ALU_ip2[3:0]) > 4'b1111); // Simplistic AC for SUB
                    Flag[2] = ~^temp[7:0];
                    alu_done = 1'b1;
                end  

                4'd3: begin  // SBB (Subtract with Borrow)
                    temp = ALU_ip1 - ALU_ip2 - {8'd0, Flag[0]};  
                    {Flag[0], ALU_op} = temp;
                    Flag[7] = temp[7];
                    Flag[6] = (temp[7:0] == 8'b0);
                    Flag[2] = ~^temp[7:0];
                    alu_done = 1'b1;
                end   

                4'd4: begin  // ANA (AND)
                    ALU_op = ALU_ip1 & ALU_ip2; 
                    Flag[0] = 1'b0; // Carry cleared
                    Flag[7] = ALU_op[7];
                    Flag[6] = (ALU_op == 8'b0);
                    Flag[4] = 1'b1; // 8080/8085 ANA sets AC
                    Flag[2] = ~^ALU_op;
                    alu_done = 1'b1;
                end 

                4'd5: begin  // XRA (XOR)
                    ALU_op = ALU_ip1 ^ ALU_ip2; 
                    Flag[0] = 1'b0; 
                    Flag[4] = 1'b0;  
                    Flag[7] = ALU_op[7];
                    Flag[6] = (ALU_op == 8'b0);
                    Flag[2] = ~^ALU_op;
                    alu_done = 1'b1;
                end 

                4'd6: begin  // ORA (OR)
                    ALU_op = ALU_ip1 | ALU_ip2; 
                    Flag[0] = 1'b0; 
                    Flag[4] = 1'b0;  
                    Flag[7] = ALU_op[7];
                    Flag[6] = (ALU_op == 8'b0);
                    Flag[2] = ~^ALU_op;
                    alu_done = 1'b1;
                end 

                4'd7: begin  // CMP (Compare)
                    temp = ALU_ip1 - ALU_ip2;
                    Flag[0] = (ALU_ip1 < ALU_ip2); 
                    Flag[7] = temp[7];
                    Flag[6] = (temp[7:0] == 8'b0);
                    Flag[2] = ~^temp[7:0];
                    alu_done = 1'b1;
                end  

                4'd8: begin // RLC
                    ALU_op = {ALU_ip1[6:0], ALU_ip1[7]};
                    Flag[0] = ALU_ip1[7];
                    alu_done = 1'b1;
                end

                4'd9: begin // RRC
                    ALU_op = {ALU_ip1[0], ALU_ip1[7:1]};
                    Flag[0] = ALU_ip1[0];
                    alu_done = 1'b1;
                end
             
                4'd10: begin // RAL
                    ALU_op = {ALU_ip1[6:0], Flag[0]}; 
                    Flag[0] = ALU_ip1[7];
                    alu_done = 1'b1;
                end  

                4'd11: begin // RAR
                    ALU_op = {Flag[0], ALU_ip1[7:1]}; 
                    Flag[0] = ALU_ip1[0];
                    alu_done = 1'b1;
                end  

                4'd12: begin // CMA (Complement A)
                    ALU_op = ~ALU_ip1; 
                    alu_done = 1'b1;
                end  

                4'd13: begin // CMC (Complement Carry)
                    Flag[0] = ~Flag[0];
                    alu_done = 1'b1;
                end

                4'd14 : begin // STC (Set Carry)
                    Flag[0] = 1'b1;
                    alu_done = 1'b1;
                end

                4'd15: begin // DAA (Decimal Adjust Accumulator)
                    temp = {1'b0, ALU_ip1};
                    if ((ALU_ip1[3:0] > 4'b1001) || Flag[4]) begin 
                        temp = temp + 9'd6;
                        Flag[4] = 1'b1;
                    end else Flag[4] = 1'b0;

                    if ((temp[7:4] > 4'b1001) || Flag[0]) begin
                        temp = temp + 9'd96; // 0x60
                        Flag[0] = 1'b1;
                    end else Flag[0] = 1'b0;

                    ALU_op = temp[7:0];
                    Flag[7] = temp[7];
                    Flag[6] = (temp[7:0] == 8'b0);
                    Flag[2] = ~^temp[7:0];
                    alu_done = 1'b1;
                end
            endcase
        end 
    end 
endmodule