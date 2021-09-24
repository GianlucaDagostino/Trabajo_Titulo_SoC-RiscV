/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021
*/
`timescale 1ns / 1ps

module Instruction_Decoder(
    input [31:0] in,
    output is_imm_valid,
    output [31:0] imm,
    output [4:0] rd_add, rs1_add, rs2_add, rs3_add,
    output [3:0] funct7_out,
    output [2:0] format_type, sub_format_type, funct3,
    output [1:0] reg_access_option, funct2
    );
    wire [6:0] opcode, funct7;
    assign {opcode , funct7   , funct3   , funct2   , rd_add  , rs1_add  , rs2_add  , rs3_add  }
        =  {in[6:0], in[31:25], in[14:12], in[26:25], in[11:7], in[19:15], in[24:20], in[31:27]};
    /*
        Format Group Classifier:
        opcode   -> Type
        0110011 -> R
        1010011 -> R (FP)
        100 00 11 -> R4 (FP- fmadd.s)
        100 01 11 -> R4 (FP- fmsub.s)
        100 11 11 -> R4 (FP- fnmadd.s)
        100 10 11 -> R4 (FP- fnmsub.s)
        0100011 -> S
        0100111 -> S (FP)
        1100011 -> B
        1101111 -> J
        0110111 -> U (lui)
        0010111 -> U (auipc)
        0010011 -> I (addi, xori, ori, andi, slli, srli, srai, slti, sltiu)
        0000011 -> I (lb, lh, lw, lbu, lhu)
        1100111 -> I (jalr)
        1110011 -> I (ecall, ebreak)
        0000111 -> I (FP)
        format_type[2:0]:
        000 -> R type
        001 -> R4 type
        011 -> S type
        100 -> B type
        101 -> U type
        110 -> J type
        010 -> I type
        111 -> Not valid type
    */
    assign format_type = (opcode[4:0]==5'b10011 & (opcode[6]^opcode[5])) ? 3'b000 : // R
                        (({opcode[6:4], opcode[1:0]}==5'b10011)          ? 3'b001 : // R4
                        (({opcode[6:3], opcode[1:0]}==6'b010011)         ? 3'b011 : // S
                        ((opcode==7'b1100011)                            ? 3'b100 : // B
                        ((opcode==7'b1101111)                            ? 3'b110 : // J
                        (({opcode[6], opcode[4:0]}==6'b010111)           ? 3'b101 : // U
                        ((opcode[1:0]==2'b11&(opcode[6:2]==5'b100|opcode[6:2]==5'b0|opcode[6:2]==5'b1
                        |opcode[6:2]==5'b11001|opcode[6:2]==5'b11100))   ? 3'b010 : // I
                                                                      3'b111)))))); // Not valid
    /*
        Sub-Format Group Classifier
            sub_format_type[2:0]:
                if format_type[2:0] = 000
                -000 -> R (FP)
                -001 -> R
                if format_type[2:0] = 001
                -000 -> R4 (FP- fmadd.s)
                -001 -> R4 (FP- fmsub.s)
                -010 -> R4 (FP- fnmsub.s)
                -011 -> R4 (FP- fnmadd.s)
              100 00 11 -> R4 (FP- fmadd.s)
              100 01 11 -> R4 (FP- fmsub.s)
              100 10 11 -> R4 (FP- fnmsub.s)
              100 11 11 -> R4 (FP- fnmadd.s)
                if format_type[2:0] = 010
                -000 -> I (FP)
                -001 -> I (addi, xori, ori, andi, slli, srli, srai, slti, sltiu)
                -010 -> I (lb, lh, lw, lbu, lhu)
                -011 -> I (jalr)
                -100 -> I (ecall, ebreak)
                if format_type[2:0] = 011
                -000 -> S (FP)
                -001 -> S
                if format_type[2:0] = 101
                -000 -> U (lui)
                -001 -> U (auipc)
                else
                -111
    */
    assign sub_format_type = (format_type==3'b000) ? (opcode[6] ? 3'b000 : 3'b001) : // R
                            ((format_type==3'b011) ? (opcode[2] ? 3'b000 : 3'b001) : // S
                            ((format_type==3'b101) ? (opcode[5] ? 3'b000 : 3'b001) : // U
                            ((format_type==3'b001) ? opcode[4:2]                   : // R4
                            ((format_type==3'b010&opcode[6:2]==5'b1)      ? 3'b000 : // I (FP)
                            ((format_type==3'b010&opcode[6:2]==5'b0)      ? 3'b010 : // I (lb, lh, lw, lbu, lhu)
                            ((format_type==3'b010&opcode[6:2]==5'b100)    ? 3'b001 : // I (addi, xori, ori, andi, slli, srli, srai, slti, sltiu)
                            ((format_type==3'b010&opcode[6:2]==5'b11001)  ? 3'b011 : // I (jalr)
                            ((format_type==3'b010&opcode[6:2]==5'b11100)  ? 3'b100 : // I (ecall, ebreak)
                                3'b111))))))));
    /*
        Opration Classifier:
        if  Funct7[6:0]=0000000: Funct7-out[3:0]=0000 
        if  Funct7[6:0]=0000001: Funct7-out[3:0]=0001
        if  Funct7[6:0]=0100000: Funct7-out[3:0]=0010
        if  Funct7[6:0]=0000100: Funct7-out[3:0]=0011
        if  Funct7[6:0]=0001000: Funct7-out[3:0]=0100
        if  Funct7[6:0]=0001100: Funct7-out[3:0]=0101
        if  Funct7[6:0]=0101100: Funct7-out[3:0]=0110
        if  Funct7[6:0]=0010000: Funct7-out[3:0]=0111
        if  Funct7[6:0]=0010100: Funct7-out[3:0]=1000
        if  Funct7[6:0]=1101000: Funct7-out[3:0]=1001
        if  Funct7[6:0]=1100000: Funct7-out[3:0]=1010
        if  Funct7[6:0]=1110000: Funct7-out[3:0]=1011
        if  Funct7[6:0]=1111000: Funct7-out[3:0]=1100
        if  Funct7[6:0]=1010000: Funct7-out[3:0]=1101
        else:
         Funct7-out[3:0]=1111
    */
    assign funct7_out = (funct7==7'b0000000) ? 4'b0000 : // 0x00
                       ((funct7==7'b0000001) ? 4'b0001 : // 0x01
                       ((funct7==7'b0100000) ? 4'b0010 : // 0x20
                       ((funct7==7'b0000100) ? 4'b0011 : 
                       ((funct7==7'b0001000) ? 4'b0100 :
                       ((funct7==7'b0001100) ? 4'b0101 :
                       ((funct7==7'b0101100) ? 4'b0110 :
                       ((funct7==7'b0010000) ? 4'b0111 :
                       ((funct7==7'b0010100) ? 4'b1000 :
                       ((funct7==7'b1101000) ? 4'b1001 :
                       ((funct7==7'b1100000) ? 4'b1010 :
                       ((funct7==7'b1110000) ? 4'b1011 :
                       ((funct7==7'b1111000) ? 4'b1100 :
                       ((funct7==7'b1010000) ? 4'b1101 :
                        4'b1111)))))))))))));
    /*
        Registers selection options
        if format-type[2:0]=000 (R):
          if sub-format-type[2:0]=000 (FP):
            if Funct7-out[3:0]=1010 o 1011 o 1101 ( fwt.w(u).s fmv.x.w fclass.s feq.s flt.s fle.s )
              reg_access_option[1:0]=10
            if Funct7-out[3:0]=1001 o 1100 ( fwt.s.w(u) fmv.w.x )
              reg_access_option[1:0]=01
            else:
              reg_access_option[1:0]=11

          if sub-format-type[2:0]=001 (no FP):
            reg_access_option[1:0]=00
        if format-type[2:0]=010 (I):
          if sub-format-type[2:0]=000 (FP):  reg_access_option[1:0]=01
          if sub-format-type[2:0]=001 o 010 o 011 o 100 (no FP):  reg_access_option[1:0]=00
        if format-type[2:0]=011 (S):
          if sub-format-type[2:0]=000 (FP):  reg_access_option[1:0]=01
          if sub-format-type[2:0]=001 (no FP):  reg_access_option[1:0]=00
        if format-type[2:0]=001 (R4):
          reg_access_option[1:0]=11
        if format-type[2:0]=100 (B):
          reg_access_option[1:0]=00
        if format-type[2:0]=101 (U) o 110 (J):
          reg_access_option[1:0]=00 o 10=00
        reg_access_option[1:0] =
            00: rd, rs1, rs2 son registros Integer
            01: rs1 es reg Integer y rd, rs2 son FP
            10: rd es reg Integer y rs1, rs2 son FP
            11: rd, rs1, rs2 son registros FP
        reg_access_option:
        |code| rd | rs1 | rs2 |
        | 00 | I  | I   | I   |
        | 01 | FP | I   | FP  |
        | 10 | I  | FP  | FP  |
        | 11 | FP | FP  | FP  |
        note: rs3 is always FP
    */
    assign reg_access_option = (format_type[2:1]==2'b10|format_type==3'b110) ? 2'b00 : // B-U-J
                              ((format_type==3'b001)                         ? 2'b11 : // R4
                              ((format_type==3'b011&sub_format_type==3'b000) ? 2'b01 : // S (FP)
                              ((format_type==3'b011&sub_format_type==3'b001) ? 2'b00 : // S (no FP)
                              ((format_type==3'b010&sub_format_type==3'b000) ? 2'b01 : // I (FP)
                              ((format_type==3'b010&sub_format_type!=3'b111) ? 2'b00 : // I (no FP)
                              ((format_type==3'b000&sub_format_type==3'b001) ? 2'b00 : // R (no FP)
                              ((format_type==3'b000&sub_format_type==3'b000&(funct7_out==4'b1010|
                               funct7_out==4'b1011|funct7_out==4'b1101    )) ? 2'b10 : // R (FP) ( fwt.w(u).s fmv.x.w fclass.s feq.s flt.s fle.s )
                              ((format_type==3'b000&sub_format_type==3'b000&(
                               funct7_out==4'b1001|funct7_out==4'b1100    )) ? 2'b01 : // R (FP) ( fwt.s.w(u) fmv.w.x )
                              ((format_type==3'b000&sub_format_type==3'b000&(
                               funct7_out!=4'b1111                        )) ? 2'b11 : // R (FP) ( ~ )
                               2'b00)))))))));
    /*
        if format-type[2:0] = 010 (I type):
         imm[31:0] = Inst[31]*ones[19:0] : Inst[30:20]
         is_imm_valid = 1
        if format-type[2:0] = 011 (S type):
         imm[31:0] = Inst[31]*ones[19:0] : Inst[30:25] : Inst[11:7]
         is_imm_valid = 1
        if format-type[2:0] = 100 (B type):
         imm[31:0] = Inst[31]*ones[19:0] : Inst[7] : Inst[30:25] : Inst[11:8] : 0
         is_imm_valid = 1
        if format-type[2:0] = 101 (U type):
         imm[31:0] = Inst[31:12] : zeros[11:0]
         is_imm_valid = 1
        if format-type[2:0] = 110 (J type):
         imm[31:0] = Inst[31]*ones[11:0] : Inst[19:12] : Inst[20] : Inst[30:21] : 0
         is_imm_valid = 1
        else:
         imm[31:0] = dont_care[31:0]
         is_imm_valid = 0
    */
    assign is_imm_valid = (format_type[2:1]==2'b01|format_type[2:1]==2'b10|format_type==3'b110) ? 1'b1 : 1'b0;
    assign imm = (format_type==3'b010) ? 32'(signed'(in[31:20]))                                    : // I
                ((format_type==3'b011) ? 32'(signed'({in[31:25], in[11:7]}))                        : // S
                ((format_type==3'b100) ? 32'(signed'({in[31], in[7], in[30:25], in[11:8], 1'b0}))   : // B
                ((format_type==3'b101) ? {in[31:12], 12'b0}                                         : // U
                ((format_type==3'b110) ? 32'(signed'({in[31], in[19:12], in[20], in[30:21], 1'b0})) : // J
                 32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx))));
endmodule

module registers_files(
    input clk,            // clock del sistema
    input [4:0] rs1_add,  // dirección reg source 1
    input [4:0] rs2_add,  // dirección reg source 2
    input [4:0] rs3_add,  // dirección reg source 3
    input [4:0] wb_add,   // dirección reg para wb
    input [31:0] wb_data, // data para wb
    input write_reg,      // pin que indica si realizar wb
    input is_wb_data_fp,  // indica si el reg de wb es fp o no
    input is_rs1_fp,      // indica si el reg source 1 es fp o no
    input is_rs2_fp,      // indica si el reg source 2 es fp o no
    output [31:0] rs1,    // data de reg source 1
    output [31:0] rs2,    // data de reg source 2
    output [31:0] rs3     // data de reg source 3
    );
    reg[31:0] int_registers[31:0];
    reg[31:0] fp_registers[31:0];
    initial for(int i=0; i<32; i++) begin
        if(i == 2)      {int_registers[i], fp_registers[i]} = {32'h2FFC, 32'b0}; // sp
        else if(i == 3) {int_registers[i], fp_registers[i]} = {32'h1800, 32'b0}; // gp
        else            {int_registers[i], fp_registers[i]} = '0;
    end
    assign rs1 = is_rs1_fp ? fp_registers[rs1_add] : int_registers[rs1_add];
    assign rs2 = is_rs2_fp ? fp_registers[rs2_add] : int_registers[rs2_add];
    assign rs3 = fp_registers[rs3_add];
    always @ (negedge clk)
        if(write_reg)
            if(is_wb_data_fp) fp_registers[wb_add] <= wb_data;
            else begin
                if(wb_add == 5'd0) int_registers[wb_add] <= 32'd0;
                else int_registers[wb_add] <= wb_data;
            end
endmodule