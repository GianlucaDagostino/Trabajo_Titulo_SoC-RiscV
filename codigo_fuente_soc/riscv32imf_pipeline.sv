/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021
*/
`timescale 1ns / 1ps

module riscv32imf_pipeline(
    input clk, rst, start, acces_to_registers_files, is_wb_data_fp_fromEEI, do_wb_fromEEI, is_rs1_fp_fromEEI, is_rs2_fp_fromEEI,
    input acces_to_prog_mem, prog_rw_fromEEI, prog_valid_mem_fromEEI, prog_is_load_unsigned_fromEEI,
    input acces_to_data_mem, data_rw_fromEEI, data_valid_mem_fromEEI, data_is_load_unsigned_fromEEI,
    input [31:0] initial_PC, prog_addr_fromEEI, prog_in_fromEEI, data_addr_fromEEI, data_in_fromEEI, wb_data_fromEEI,
    input [1:0] prog_byte_half_word_fromEEI, data_byte_half_word_fromEEI,
    input [4:0] rs1_add_fromEEI, rs2_add_fromEEI, wb_add_fromEEI,
    output prog_ready_toEEI, prog_out_of_range_toEEI, data_ready_toEEI, data_out_of_range_toEEI,
    output reg ready,
    output [1:0] exit_status,
    output [31:0] prog_out_toEEI, data_out_toEEI, rs1_toEEI, rs2_toEEI, PC
    /*
        exit_status[1:0] =
            00 -> ecall
            11 -> ebreak
            01 -> program out of range
            10 -> memory out of range
    */
    );
    typedef enum {waiting_state, loop_state_1, loop_state_2_normal, loop_state_2_chazzard, loop_state_3, prog_error_state, final_state} state_type;
    state_type actual_state, next_state;
    reg set_regs, is_the_beginning, enable_execution, not_valid_EX, not_valid_MEM, not_valid_WB, control_bubble, acces_to_fpu_EX,
        acces_to_mem_EX, acces_to_mem_MEM, is_imm_valid_EX, is_ecall_EX, is_ecall_MEM, is_ebreak_EX, is_ebreak_MEM, is_ecall_WB, is_ebreak_WB;
    reg [4:0] rd_add_EX, rd_add_MEM, rd_add_WB, rs1_add_EX, rs2_add_EX, rs3_add_EX;
    reg [3:0] funct7_out_EX;
    reg [2:0] format_type_MEM, sub_format_type_MEM, format_type_EX, sub_format_type_EX, format_type_WB, funct3_EX, funct3_MEM;
    reg [1:0] reg_access_option_EX, reg_access_option_MEM, reg_access_option_WB;
    reg [31:0] new_PC, PC_IF, PC_DR, PC_EX, PC_MEM, PC_WB, inst_DR, imm_EX, rs1_EX, rs2_EX, rs3_EX, final_res_MEM, operand3_MEM, rd_WB;
    wire is_ecall_DR, is_ebreak_DR, acces_to_fpu_DR, acces_to_mem_DR, not_valid_DR, is_imm_valid_DR, ready_fpu, enable_fpu, exit, done,
         ready_prog_mem, out_of_range_prog_mem, ready_data_mem, out_of_range_data_mem, rw_data_mem, is_load_unsigned_data_mem, branch_condition, control_hazard;
    wire [6:0] ignored_signals;
    wire [4:0] rd_add_DR, rs1_add_DR, rs2_add_DR, rs3_add_DR, alu_option, fpu_option;
    wire [3:0] funct7_out_DR;
    wire [2:0] format_type_DR, sub_format_type_DR, funct3_DR, rm2fpu;
    wire [1:0] reg_access_option_DR, byte_half_word_data_mem;
    wire [31:0] jalr_pc, branch_PC, rs1_DR, rs2_DR, rs3_DR, imm_DR, rd_MEM, operand1_EX, operand2_EX, operand3_EX, final_res_EX, inst_IF, res_alu, res_fpu, data_out_data_mem;         
    // interface con EEI
    assign {prog_ready_toEEI, prog_out_of_range_toEEI, data_ready_toEEI, data_out_of_range_toEEI, prog_out_toEEI, data_out_toEEI,    rs1_toEEI, rs2_toEEI} =
           {ready_prog_mem,   out_of_range_prog_mem,   ready_data_mem,   out_of_range_data_mem,   inst_IF,        data_out_data_mem, rs1_DR,    rs2_DR}; 
    assign PC = (exit_status[1]^exit_status[0]) ? (exit_status[0] ? PC_IF : PC_MEM) : PC_WB;
    // exit_status_selection
    assign exit_status = is_ecall_WB                                                    ? 2'b00 : (
                         is_ebreak_WB                                                   ? 2'b11 : (
                         (acces_to_mem_MEM & out_of_range_data_mem) ? 2'b10 : (
                         (out_of_range_prog_mem & ~control_hazard)    ? 2'b01 : (
                         2'b00)))); 
    // data_mem_options_selection
    assign rw_data_mem = (format_type_MEM==3'b011) ? 1'b1 : 1'b0; // only 1 in S type instruction
    assign is_load_unsigned_data_mem = (format_type_MEM==3'b010 & funct3_MEM[2:1]==2'b10) ? 1'b1 : 1'b0; // only 1 in I type instruction and funct3= 4 o 5
    assign byte_half_word_data_mem = (funct3_MEM[1:0]==2'b00) ? 2'b10 : // funct3= 0 o 4 -byte
                                    ((funct3_MEM[1:0]==2'b01) ? 2'b01 : // funct3= 1 o 5 -half
                                                                2'b00); // funct3= 2     -word (default)
    // final_alu_fpu_res_selection
    assign final_res_EX =
        (({format_type_EX, sub_format_type_EX}==6'b000_000 & {funct7_out_EX, funct3_EX}!=7'b1011_000 & {funct7_out_EX, funct3_EX}!=7'b1100_000) | // se excluyen fmv.x.w y fmv.w.x
        format_type_EX==3'b001) ? res_fpu    : // R (fp)   o R4
        (({format_type_EX, sub_format_type_EX}==6'b000_000 & (funct7_out_EX==4'b1011 | funct7_out_EX==4'b1100)) ? operand1_EX : // fmv.x.w y fmv.w.x
        (({format_type_EX, sub_format_type_EX}==6'b010_011 | format_type_EX==3'b110) ? PC_EX+32'b100 : // I (jalr) o J
        ((format_type_EX==3'b101)    ?   ( operand2_EX + (sub_format_type_EX[0] ? PC_EX : 32'b0) )   : // U
        res_alu))); // default                                                                 // default 
    // mux rd
    assign rd_MEM = (format_type_MEM==3'b010 & ~sub_format_type_MEM[2] & ~sub_format_type_MEM[0]) ? data_out_data_mem : final_res_MEM;
    // sub_decoder
    assign is_ecall_DR  = (format_type_DR==3'b010 & sub_format_type_DR==3'b100 & imm_DR==32'b0) ? 1'b1 : 1'b0;
    assign is_ebreak_DR = (format_type_DR==3'b010 & sub_format_type_DR==3'b100 & imm_DR==32'b1) ? 1'b1 : 1'b0;
    assign acces_to_fpu_DR = (
            format_type_DR==3'b001 | ( // R4
            {format_type_DR, sub_format_type_DR}==6'b0 & {funct7_out_DR, funct3_DR}!=7'b1011_000 & {funct7_out_DR, funct3_DR}!=7'b1100_000 ) // R (fp) - {fmv.x.w, fmv.w.x}
        ) ? 1'b1 : 1'b0;
    assign acces_to_mem_DR = (format_type_DR==3'b011 | (format_type_DR==3'b010 & ~sub_format_type_DR[2] & ~sub_format_type_DR[0])) ? 1'b1 : 1'b0;
    assign not_valid_DR = format_type_DR==3'b111 ? 1'b1 : 1'b0;
    // next_PC_selection
    assign control_hazard = ( ({format_type_EX, branch_condition}==4'b100_1 | format_type_EX==3'b110) | ({format_type_EX, sub_format_type_EX}==6'b010_011) ) ? 1'b1 : 1'b0;
    assign jalr_pc = operand1_EX+operand2_EX;
    assign branch_PC = ({format_type_EX, branch_condition}==4'b100_1 | format_type_EX==3'b110) ? PC_EX+operand2_EX : // B | J
                      (({format_type_EX, sub_format_type_EX}==6'b010_011)                  ? {jalr_pc[31:1], 1'b0} : // I (jalr)
                      32'b0);
    // control_signals
    assign exit = (is_ecall_WB | is_ebreak_WB | 
                 (out_of_range_prog_mem & ~control_hazard) |
                 (acces_to_mem_MEM & out_of_range_data_mem) ) ? 1'b1 : 1'b0;
    assign done = (((ready_prog_mem & ~out_of_range_prog_mem) | control_hazard) &
                   ((acces_to_fpu_EX & ready_fpu) | ~acces_to_fpu_EX) &
                   ((acces_to_mem_MEM & ready_data_mem & ~out_of_range_data_mem) | ~acces_to_mem_MEM)) ? 1'b1 : 1'b0;
    // FSM controller
    always_comb
        case (actual_state)
            default: begin
                {is_the_beginning, ready}                    = 2'b00;
                {enable_execution, control_bubble, set_regs} = 3'b000;
                next_state = actual_state;
            end
            waiting_state: begin
                {is_the_beginning, ready}                    = {start, 1'b0};
                {enable_execution, control_bubble, set_regs} = 3'b000;
                next_state = start ? loop_state_1 : waiting_state;
            end
            loop_state_1: begin
                {is_the_beginning, ready}                    = 2'b00;
                {enable_execution, control_bubble, set_regs} = 3'b100;
                next_state = start ? (exit ? final_state :
                    (done ? (control_hazard ? loop_state_2_chazzard : loop_state_2_normal)
                    : loop_state_1)) : waiting_state;
            end
            loop_state_2_normal: begin
                {is_the_beginning, ready}                    = 2'b00;
                {enable_execution, control_bubble, set_regs} = 3'b101;
                next_state = loop_state_3;
            end
            loop_state_2_chazzard: begin
                {is_the_beginning, ready}                    = 2'b00;
                {enable_execution, control_bubble, set_regs} = 3'b111;
                next_state = loop_state_3;
            end
            loop_state_3: begin
                {is_the_beginning, ready}                    = 2'b00;
                {enable_execution, control_bubble, set_regs} = 3'b000;
                next_state = loop_state_1;
            end
            final_state: begin
                {is_the_beginning, ready}                    = 2'b01;
                {enable_execution, control_bubble, set_regs} = 3'b100;
                next_state = start ? final_state : waiting_state;;
            end
        endcase
    always_ff @(posedge(clk)) begin // el orden SI importa
        new_PC = is_the_beginning ? initial_PC : (set_regs ? (control_bubble ? branch_PC : PC_IF+32'b100) : PC_IF); // PC_generator
        if(is_the_beginning) begin // reset
            // PipelineReg_MEM2WB
            {PC_WB,  rd_WB,  rd_add_WB,  format_type_WB,  reg_access_option_WB,  not_valid_WB,  is_ebreak_WB,  is_ecall_WB } = 0;
            // PipelineReg_EX2MEM
            {PC_MEM, final_res_MEM, operand3_MEM, rd_add_MEM, format_type_MEM, sub_format_type_MEM, funct3_MEM,
             reg_access_option_MEM, acces_to_mem_MEM, not_valid_MEM, is_ebreak_MEM, is_ecall_MEM} = 0;
        end
        else if(set_regs) begin // set
            // PipelineReg_MEM2WB
            {PC_WB,  rd_WB,  rd_add_WB,  format_type_WB,  reg_access_option_WB,  not_valid_WB,  is_ebreak_WB,  is_ecall_WB }
            =
            {PC_MEM, rd_MEM, rd_add_MEM, format_type_MEM, reg_access_option_MEM, not_valid_MEM, is_ebreak_MEM, is_ecall_MEM};
            // PipelineReg_EX2MEM
            {PC_MEM, final_res_MEM, operand3_MEM, rd_add_MEM, format_type_MEM, sub_format_type_MEM, funct3_MEM,
             reg_access_option_MEM, acces_to_mem_MEM, not_valid_MEM, is_ebreak_MEM, is_ecall_MEM}
            =
            {PC_EX,  final_res_EX,  operand3_EX,  rd_add_EX,  format_type_EX,  sub_format_type_EX,  funct3_EX,
             reg_access_option_EX,  acces_to_mem_EX,  not_valid_EX,  is_ebreak_EX,  is_ecall_EX };
        end
        if((control_bubble & set_regs) | is_the_beginning) begin // reset (c. hazard)
            // PipelineReg_DR2EX
            {PC_EX, imm_EX, rs1_EX, rs2_EX, rs3_EX, rd_add_EX, rs1_add_EX, rs2_add_EX, rs3_add_EX,
             funct7_out_EX, funct3_EX, format_type_EX, sub_format_type_EX, reg_access_option_EX,
             is_imm_valid_EX, acces_to_fpu_EX, acces_to_mem_EX, not_valid_EX, is_ebreak_EX, is_ecall_EX} = 0;
            // PipelineReg_IF2DR
            {PC_DR, inst_DR} = 0;
        end
        else if(~control_bubble & set_regs) begin // set (c. hazard)
            // PipelineReg_DR2EX
            {PC_EX, imm_EX, rs1_EX, rs2_EX, rs3_EX, rd_add_EX, rs1_add_EX, rs2_add_EX, rs3_add_EX,
             funct7_out_EX, funct3_EX, format_type_EX, sub_format_type_EX, reg_access_option_EX,
             is_imm_valid_EX, acces_to_fpu_EX, acces_to_mem_EX, not_valid_EX, is_ebreak_EX, is_ecall_EX}
            =
            {PC_DR, imm_DR, rs1_DR, rs2_DR, rs3_DR, rd_add_DR, rs1_add_DR, rs2_add_DR, rs3_add_DR,
             funct7_out_DR, funct3_DR, format_type_DR, sub_format_type_DR, reg_access_option_DR,
             is_imm_valid_DR, acces_to_fpu_DR, acces_to_mem_DR, not_valid_DR, is_ebreak_DR, is_ecall_DR};
            // PipelineReg_IF2DR
            {PC_DR, inst_DR} = {PC_IF, inst_IF};
        end
        if(is_the_beginning | set_regs) PC_IF = new_PC; // PC_generator
        actual_state = rst ? waiting_state : next_state;
    end
    // prog_memory
    memory #(.initial_option(2)) prog_memory_unit(
        .clk(clk), .rst(rst),
        // inputs
        .rw(              (acces_to_prog_mem & ~start) ? prog_rw_fromEEI               : 1'b0),
        .valid(           (acces_to_prog_mem & ~start) ? prog_valid_mem_fromEEI        : enable_execution),
        .addr(            (acces_to_prog_mem & ~start) ? prog_addr_fromEEI             : PC_IF),
        .data_in(         (acces_to_prog_mem & ~start) ? prog_in_fromEEI               : 32'b0),
        .byte_half_word(  (acces_to_prog_mem & ~start) ? prog_byte_half_word_fromEEI   : 2'b0),
        .is_load_unsigned((acces_to_prog_mem & ~start) ? prog_is_load_unsigned_fromEEI : 1'b1),
        // outputs
        .ready(ready_prog_mem), .out_of_range(out_of_range_prog_mem), .data_out(inst_IF)
    );
    // data_memory
    memory #(.initial_option(1)) data_memory_unit(
        .clk(clk), .rst(rst),
        // inputs
        .rw(              (acces_to_data_mem & ~start) ? data_rw_fromEEI               : rw_data_mem),
        .valid(           (acces_to_data_mem & ~start) ? data_valid_mem_fromEEI        : acces_to_mem_MEM & enable_execution),
        .addr(            (acces_to_data_mem & ~start) ? data_addr_fromEEI             : final_res_MEM),
        .data_in(         (acces_to_data_mem & ~start) ? data_in_fromEEI               : operand3_MEM),
        .byte_half_word(  (acces_to_data_mem & ~start) ? data_byte_half_word_fromEEI   : byte_half_word_data_mem),
        .is_load_unsigned((acces_to_data_mem & ~start) ? data_is_load_unsigned_fromEEI : is_load_unsigned_data_mem),
        // outputs
        .ready(ready_data_mem), .out_of_range(out_of_range_data_mem), .data_out(data_out_data_mem)
    );
    // Instruction_Decoder
    Instruction_Decoder Instruction_Decoder_unit(
        .in(inst_DR),
        .is_imm_valid(is_imm_valid_DR), .imm(imm_DR),
        .rd_add(rd_add_DR), .rs1_add(rs1_add_DR), .rs2_add(rs2_add_DR), .rs3_add(rs3_add_DR),
        .funct7_out(funct7_out_DR), .format_type(format_type_DR), .sub_format_type(sub_format_type_DR),
        .funct3(funct3_DR), .funct2(ignored_signals[6:5]), .reg_access_option(reg_access_option_DR)
    );
    // registers_files
    registers_files registers_files_unit(
        .clk(clk),
        // inputs
        .rs1_add( (acces_to_registers_files & ~start) ? rs1_add_fromEEI : rs1_add_DR),
        .rs2_add( (acces_to_registers_files & ~start) ? rs2_add_fromEEI : rs2_add_DR),
        .rs3_add( rs3_add_DR ),
        .wb_add(  (acces_to_registers_files & ~start) ? wb_add_fromEEI  : rd_add_WB),
        .wb_data( (acces_to_registers_files & ~start) ? wb_data_fromEEI : rd_WB),
        .write_reg( (acces_to_registers_files & ~start) ? do_wb_fromEEI :
           ((format_type_WB==3'b011 | format_type_WB==3'b100 | not_valid_WB | is_ecall_WB | is_ebreak_WB) ? 1'b0 : 1'b1) ),
        .is_wb_data_fp( (acces_to_registers_files & ~start) ? is_wb_data_fp_fromEEI : reg_access_option_WB[0]),
        .is_rs1_fp( (acces_to_registers_files & ~start) ? is_rs1_fp_fromEEI : reg_access_option_DR[1]),
        .is_rs2_fp( (acces_to_registers_files & ~start) ? is_rs2_fp_fromEEI : (reg_access_option_DR[1] | reg_access_option_DR[0])),
        // outputs
        .rs1(rs1_DR), .rs2(rs2_DR), .rs3(rs3_DR)
    );
    // forwarding_unit
    forwarding_unit forwarding_unit(
        .is_imm_valid_EX(is_imm_valid_EX), .ready_data_mem(ready_data_mem), .valid_data_mem(acces_to_mem_MEM),
        .reg_access_option_EX(reg_access_option_EX), .reg_access_option_MEM(reg_access_option_MEM), .reg_access_option_WB(reg_access_option_WB),
        .format_type_EX(format_type_EX), .format_type_MEM(format_type_MEM), .format_type_WB(format_type_WB), .sub_format_type_MEM(sub_format_type_MEM),
        .rs1_add_EX(rs1_add_EX), .rs2_add_EX(rs2_add_EX), .rs3_add_EX(rs3_add_EX), .rd_add_MEM(rd_add_MEM), .rd_add_WB(rd_add_WB),
        .rs1_EX(rs1_EX), .rs2_EX(rs2_EX), .rs3_EX(rs3_EX), .rd_MEM(rd_MEM), .rd_WB(rd_WB), .imm_EX(imm_EX),
        .enable_fpu(enable_fpu), .operand1_EX(operand1_EX), .operand2_EX(operand2_EX), .operand3_EX(operand3_EX)
    );
    // alu_op_selection
    alu_op_selection alu_op_selection_unit(
        .imm_11_5(operand2_EX[11:5]), .funct7_out(funct7_out_EX),
        .format_type(format_type_EX), .sub_format_type(sub_format_type_EX), .funct3(funct3_EX),
        .alu_option(alu_option)
    );
    // ALU
    ALU ALU_unit(
        .in1(operand1_EX), .in2((format_type_EX==3'b100) ? operand3_EX : operand2_EX), // is B type?
        .operation(alu_option),
        .res(res_alu), .boolean_res(branch_condition)
    );
    // fpu_op_selection
    fpu_op_selection fpu_op_selection_unit(
        .rs2_add(rs2_add_EX), .funct7_out(funct7_out_EX),
        .format_type(format_type_EX), .sub_format_type(sub_format_type_EX), .funct3(funct3_EX), .rm_from_fcsr(3'b000),
        .rm2fpu(rm2fpu), .fpu_option(fpu_option)
    );
    // FPU
    FPU FPU_unit(
        .start(acces_to_fpu_EX & enable_fpu & enable_execution), .rst(rst | ~enable_execution), .clk(clk), .rm(rm2fpu),
        .option(fpu_option), .in1(operand1_EX), .in2(operand2_EX), .in3(operand3_EX),
        .NV(ignored_signals[4]), .NX(ignored_signals[3]), .UF(ignored_signals[2]), .OF(ignored_signals[1]), .DZ(ignored_signals[0]),
        .ready(ready_fpu), .out(res_fpu)
    );
endmodule

module forwarding_unit(
    input is_imm_valid_EX, ready_data_mem, valid_data_mem,
    input [1:0] reg_access_option_EX, reg_access_option_MEM, reg_access_option_WB,
    input [2:0] format_type_EX, format_type_MEM, format_type_WB, sub_format_type_MEM,
    input [4:0] rs1_add_EX, rs2_add_EX, rs3_add_EX, rd_add_MEM, rd_add_WB,
    input [31:0] rs1_EX, rs2_EX, rs3_EX, rd_MEM, rd_WB, imm_EX,
    output enable_fpu,
    output [31:0] operand1_EX, operand2_EX, operand3_EX
    );
    /*
        reg_access_option:
        |code| rd | rs1 | rs2 |
        | 00 | I  | I   | I   |
        | 01 | FP | I   | FP  |
        | 10 | I  | FP  | FP  |
        | 11 | FP | FP  | FP  |
        note: rs3 is always FP
    */
    wire [31:0] final_rs1, final_rs2, final_rs3;
    // checking rs1, rs2, rs3: se debe checkear MEM primero y despues WB (debido a que MEM el la inst inmediatamente precedente)
    //                   calza la dirección         no se trata de x0                                   es un write back por realizar                       son del mismo tipo (integer/fp)
    assign final_rs1 = ( rs1_add_EX==rd_add_MEM & ~( rd_add_MEM==5'b0 & ~reg_access_option_MEM[0] ) & format_type_MEM!=3'b011 & format_type_MEM!=3'b100 & reg_access_option_EX[1]==reg_access_option_MEM[0] ) ? rd_MEM : (
                       ( rs1_add_EX==rd_add_WB  & ~( rd_add_WB ==5'b0 & ~reg_access_option_WB [0] ) & format_type_WB !=3'b011 & format_type_WB !=3'b100 & reg_access_option_EX[1]==reg_access_option_WB[0]  ) ? rd_WB  : (
                         rs1_EX));
    assign final_rs2 = ( rs2_add_EX==rd_add_MEM & ~( rd_add_MEM==5'b0 & ~reg_access_option_MEM[0] ) & format_type_MEM!=3'b011 & format_type_MEM!=3'b100 & ((reg_access_option_EX==2'b0 & ~reg_access_option_MEM[0]) | (reg_access_option_EX!=2'b0 & reg_access_option_MEM[0])) ) ? rd_MEM : (
                       ( rs2_add_EX==rd_add_WB  & ~( rd_add_WB ==5'b0 & ~reg_access_option_WB [0] ) & format_type_WB !=3'b011 & format_type_WB !=3'b100 & ((reg_access_option_EX==2'b0 & ~reg_access_option_WB[0] ) | (reg_access_option_EX!=2'b0 & reg_access_option_WB[0] )) ) ? rd_WB  : (
                         rs2_EX));
    assign final_rs3 = ( rs3_add_EX==rd_add_MEM & ~( rd_add_MEM==5'b0 & ~reg_access_option_MEM[0] ) & format_type_MEM!=3'b011 & format_type_MEM!=3'b100 & reg_access_option_MEM[0] ) ? rd_MEM : (
                       ( rs3_add_EX==rd_add_WB  & ~( rd_add_WB ==5'b0 & ~reg_access_option_WB [0] ) & format_type_WB !=3'b011 & format_type_WB !=3'b100 & reg_access_option_WB [0] ) ? rd_WB  : (
                         rs3_EX));
    // final outputs (analogo al caso single cycle)
    assign operand1_EX = final_rs1;
    assign operand2_EX = is_imm_valid_EX ? imm_EX : final_rs2;
    assign operand3_EX = (format_type_EX==3'b011 | format_type_EX==3'b100) ? final_rs2 : final_rs3;
    // permite la ejecución de la FPU, es importante en las instrucciones load cuando hay data hazard pues debe esperar a que se obtenga el dato de la memoria
    assign enable_fpu = ( // si alguno de los operandos depende de rd_MEM                                                                                       
          ( (rs1_add_EX==rd_add_MEM & format_type_EX!=3'b101 & format_type_EX!=3'b110) | // no aplica para U y J
            (rs2_add_EX==rd_add_MEM & (~is_imm_valid_EX | format_type_EX==3'b011 | format_type_EX==3'b100)) | // aplica si imm es inválido o para B o S
            (rs3_add_EX==rd_add_MEM & format_type_EX==3'b001) // aplica para R4
          ) & (~sub_format_type_MEM[2] & ~sub_format_type_MEM[0] & format_type_MEM==3'b010 & valid_data_mem) // y es una instrucción de tipo load (en MEM)
          & ~( rd_add_MEM==5'b0 & ~reg_access_option_MEM[0] ) // y no se trata de x0=zero
          ) ? ready_data_mem : 1'b1; // se espera a que el dato sea valido
endmodule