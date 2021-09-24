/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021
*/
`timescale 1ns / 1ps

module alu_op_selection(
    input [6:0] imm_11_5, // imm[11:5]
    input [3:0] funct7_out,
    input [2:0] format_type, sub_format_type, funct3,
    output reg [4:0] alu_option
    );
    always_comb
        if(format_type==3'b000 & sub_format_type==3'b001) // R (no FP)
            case(funct3)
                3'b000: alu_option = (funct7_out==4'b0000) ? 5'b00_000 : // add
                                    ((funct7_out==4'b0010) ? 5'b00_001 : // sub
                                    ((funct7_out==4'b0001) ? 5'b10_000 : // mul
                                        5'bxx_xxx));
                3'b001: alu_option = (funct7_out==4'b0000) ? 5'b00_101 : // sll
                                    ((funct7_out==4'b0001) ? 5'b11_000 : // mulh
                                        5'bxx_xxx);
                3'b010: alu_option = (funct7_out==4'b0000) ? 5'b01_010 : // slt
                                    ((funct7_out==4'b0001) ? 5'b11_010 : // mulsu
                                        5'bxx_xxx);
                3'b011: alu_option = (funct7_out==4'b0000) ? 5'b01_011 : // sltu
                                    ((funct7_out==4'b0001) ? 5'b11_001 : // mulu
                                        5'bxx_xxx);
                3'b100: alu_option = (funct7_out==4'b0000) ? 5'b00_010 : // xor
                                    ((funct7_out==4'b0001) ? 5'b10_011 : // div
                                        5'bxx_xxx);
                3'b101: alu_option = (funct7_out==4'b0000) ? 5'b00_110 : // srl
                                    ((funct7_out==4'b0010) ? 5'b00_111 : // sra
                                    ((funct7_out==4'b0001) ? 5'b10_100 : // divu
                                        5'bxx_xxx));
                3'b110: alu_option = (funct7_out==4'b0000) ? 5'b00_011 : // or
                                    ((funct7_out==4'b0001) ? 5'b10_101 : // rem
                                        5'bxx_xxx);
                3'b111: alu_option = (funct7_out==4'b0000) ? 5'b00_100 : // and
                                    ((funct7_out==4'b0001) ? 5'b10_111 : // remu
                                        5'bxx_xxx);
                default: alu_option = 5'bxx_xxx;
            endcase
        else if(format_type==3'b100) // B
            case(funct3)
                3'b000: alu_option = 5'b01_000; // beq
                3'b001: alu_option = 5'b01_001; // bne
                3'b100: alu_option = 5'b01_010; // blt
                3'b101: alu_option = 5'b01_100; // bge
                3'b110: alu_option = 5'b01_011; // bltu
                3'b111: alu_option = 5'b01_101; // bgeu
                default: alu_option = 5'bxx_xxx;
            endcase
        else if(format_type==3'b010) // I
            if(sub_format_type==3'b001) // (addi, xori, ori, andi, slli, srli, srai, slti, sltiu)
                case (funct3)
                    3'b000: alu_option = 5'b00_000; // addi
                    3'b001: alu_option = 5'b00_101; // slli
                    3'b010: alu_option = 5'b01_010; // slti
                    3'b011: alu_option = 5'b01_011; // sltiu
                    3'b100: alu_option = 5'b00_010; // xori
                    3'b101: alu_option = (imm_11_5==7'b000_0000) ? 5'b00_110 : // srli
                                        ((imm_11_5==7'b010_0000) ? 5'b00_111 : // srai
                                                                   5'bxx_xxx);
                    3'b110: alu_option = 5'b 00_011; // ori
                    3'b111: alu_option = 5'b 00_100; // andi
                    default: alu_option = 5'bxx_xxx;
                endcase
            else
                alu_option = 5'b00_000;
        else 
            alu_option = 5'b00_000; // S(011) & default
endmodule

module ALU(
    input [31:0] in1,
    input [31:0] in2,
    input [4:0] operation,
    output [31:0] res,
    output boolean_res
    );
    wire [31:0] res_simple, res_mul;
    wire temp_boolean_res;
    assign res         = (operation[4:3] == 2'b00) ? res_simple :
                        ((operation[4] == 1'b1)    ? res_mul :
                        ((operation[4:3] == 2'b01) ? (temp_boolean_res ? 32'b1 : 32'b0) : 32'bX));
    assign boolean_res = (operation[4:3] == 2'b01) ? temp_boolean_res : 1'b0;
/*
    over/under-flow se debe controlar mediante software
    integer_sub_alu_simple:
        operation=00_000: + add
        operation=00_001: - sub
        operation=00_010: ^ xor
        operation=00_011: | or
        operation=00_100: & and
        operation=00_101: << shift left
        operation=00_110: >> shift rigth
        operation=00_111: >> shift rigth (MSB extend)
    integer_sub_alu_comparison:
        operation=01_000: == equality
        operation=01_001: != difference
        operation=01_010: < is less than
        operation=01_011: < is less than (unsigned)
        operation=01_100: >= is bigger or equal
        operation=01_101: >= is bigger or equal (unsigned)
    integer_sub_alu_mul:
        operation=10_000: * mul
        operation=11_000: * mul high
        operation=11_001: * mul high (unsigned)
        operation=11_010: * mul high (signed*unsigned)
        operation=10_011: / div
        operation=10_100: / div (unsigned)
        operation=10_101: % modulo
        operation=10_111: % modulo (unsigned)
*/
    integer_sub_alu_simple      simple_alu    (in1, in2, operation[2:0], res_simple);
    integer_sub_alu_comparison  comparison_alu(in1, in2, operation[2:0], temp_boolean_res);
    integer_sub_alu_mul         mul_alu       (in1, in2, operation[2:0], operation[3], res_mul);
endmodule

module integer_sub_alu_simple(
    input [31:0] in1,
    input [31:0] in2,
    input [2:0] sub_option,
    output reg [31:0] res
    );
    always_comb begin
        case(sub_option)
            3'b000: // operation=00_000: + add
                res = in1 + in2;
            3'b001: // operation=00_001: - sub
                res = in1 - in2;
            3'b010: // operation=00_010: ^ xor
                res = in1 ^ in2;
            3'b011: // operation=00_011: | or
                res = in1 | in2;
            3'b100: // operation=00_100: & and
                res = in1 & in2;
            3'b101: // operation=00_101: << shift left
                res = (unsigned'(in1) <<unsigned'(in2[4:0]));
            3'b110: // operation=00_110: >> shift rigth
                res = (unsigned'(in1) >>unsigned'(in2[4:0]));
            3'b111: // operation=00_111: >> shift rigth (MSB extend)
                res = (signed'(in1) >>>unsigned'(in2[4:0]));
            default:
                res = 32'bX;
        endcase
    end
endmodule

module integer_sub_alu_comparison(
    input [31:0] in1,
    input [31:0] in2,
    input [2:0] sub_option,
    output reg boolean_res
    );
    always_comb begin
        case(sub_option)
            3'b000: // operation=01_000: == equality
                boolean_res = (in1 == in2) ? 1'b1 : 1'b0;
            3'b001: // operation=01_001: != difference
                boolean_res = (in1 != in2) ? 1'b1 : 1'b0;
            3'b010: // operation=01_010: < is less than
                boolean_res = (signed'(in1) <signed'(in2)) ? 1'b1 : 1'b0;
            3'b011: // operation=01_011: < is less than (unsigned)
                boolean_res = (unsigned'(in1) <unsigned'(in2)) ? 1'b1 : 1'b0;
            3'b100: // operation=01_100: >= is bigger or equal
                boolean_res = (signed'(in1) >=signed'(in2)) ? 1'b1 : 1'b0;
            3'b101: // operation=01_101: >= is bigger or equal (unsigned)
                boolean_res = (unsigned'(in1) >=unsigned'(in2)) ? 1'b1 : 1'b0;
            default:
                boolean_res = 1'b0;
        endcase
    end
endmodule

module integer_sub_alu_mul(
    input [31:0] in1,
    input [31:0] in2,
    input [2:0] sub_option,
    input upper_res,
    output [31:0] res
    );
    reg [63:0] temp_res;
    assign res = upper_res ? temp_res[63:32] : temp_res[31:0];
    always_comb begin
        case(sub_option)
            3'b000: // operation=10_000: * mul - operation=11_000: * mul high
                temp_res = 64'( signed'(in1) * signed'(in2) );
            3'b001: // operation=11_001: * mul high (unsigned)
                temp_res = 64'( unsigned'(in1) * unsigned'(in2) );
            3'b010: // operation=11_010: * mul high (signed*unsigned)
                temp_res = 64'( signed'({in1[31], in1}) * signed'({1'b0, in2}) );
            3'b011: // operation=10_011: / div
                temp_res = in2==0 ? 64'b11111111111111111111111111111111 : {32'b0, 32'( signed'(in1) / signed'(in2) )};
            3'b100: // operation=10_100: / div (unsigned)
                temp_res = in2==0 ? 64'b11111111111111111111111111111111 : {32'b0, 32'( unsigned'(in1) / unsigned'(in2) )};
            3'b101: // operation=10_101: % modulo
                temp_res = in2==0 ? in1 : {32'b0, 32'( signed'(in1) % signed'(in2) )};
            3'b111: // operation=10_111: % modulo (unsigned)
                temp_res = in2==0 ? in1 : {32'b0, 32'( unsigned'(in1) % unsigned'(in2) )};
            default:
                temp_res = 64'bX;
        endcase
    end
endmodule