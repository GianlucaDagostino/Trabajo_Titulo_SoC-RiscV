/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021
*/
`timescale 1ns / 1ps

module riscv32imf_singlecycle(
    input clk, rst, start, acces_to_registers_files, is_wb_data_fp_fromEEI, do_wb_fromEEI, is_rs1_fp_fromEEI, is_rs2_fp_fromEEI,
    input acces_to_prog_mem, prog_rw_fromEEI, prog_valid_mem_fromEEI, prog_is_load_unsigned_fromEEI,
    input acces_to_data_mem, data_rw_fromEEI, data_valid_mem_fromEEI, data_is_load_unsigned_fromEEI,
    input [31:0] initial_PC, prog_addr_fromEEI, prog_in_fromEEI, data_addr_fromEEI, data_in_fromEEI, wb_data_fromEEI,
    input [1:0] prog_byte_half_word_fromEEI, data_byte_half_word_fromEEI,
    input [4:0] rs1_add_fromEEI, rs2_add_fromEEI, wb_add_fromEEI,
    output prog_ready_toEEI, prog_out_of_range_toEEI, data_ready_toEEI, data_out_of_range_toEEI,
    output reg ready,
    output reg [1:0] exit_status,
    output [31:0] prog_out_toEEI, data_out_toEEI, rs1_toEEI, rs2_toEEI, PC
    /*
        exit_status[1:0] =
            00 -> ecall
            11 -> ebreak
            01 -> program out of range or not valid inst
            10 -> memory out of range
    */
    );    
    typedef enum {
        waiting_state,
        initial_state,
        program_loop_main,
        program_loop_fpu,
        program_loop_mem,
        program_loop_new_pc_wb,
        program_loop_read_inst,
        final_state
    } state_type;
    state_type actual_state, next_state;    
    // Controller signals
    reg is_the_beginning, valid_prog_mem, valid_data_mem, start_fpu, set_pc, set_inst, do_wb;
    wire ready_fpu, ready_prog_mem, out_of_range_prog_mem, ready_data_mem, out_of_range_data_mem, is_ecall, is_ebreak, acces_to_fpu, acces_to_mem, not_valid;
    // Datapath signals
    wire is_imm_valid, branch_condition, rw_data_mem, is_load_unsigned_data_mem;
    wire [4:0] rs1_add, rs2_add, rs3_add, rd_add, alu_option, fpu_option, ignored_flags;
    wire [3:0] funct7_out;
    wire [2:0] format_type, sub_format_type, funct3, rm2fpu;
    wire [1:0] reg_access_option, byte_half_word_data_mem, funct2;
    wire [31:0] jalr_pc, inst, inst2reg, PC2reg, imm, rs2, rs3, rd, operand1, operand2, operand3, res_alu, res_fpu, EX_out, data_out_data_mem, next_PC;
    // interface con EEI
    assign {prog_ready_toEEI, prog_out_of_range_toEEI, prog_out_toEEI} = {ready_prog_mem, out_of_range_prog_mem, inst2reg};
    assign {data_ready_toEEI, data_out_of_range_toEEI, data_out_toEEI} = {ready_data_mem, out_of_range_data_mem, data_out_data_mem};
    assign {rs1_toEEI, rs2_toEEI} = {operand1, rs2};
    // PC predictor
    assign PC2reg = is_the_beginning ? initial_PC : next_PC;
    // mux for operand2
    assign operand2 = is_imm_valid ? imm : rs2;
    // mux for operand3
    assign operand3 = (is_imm_valid & (format_type==3'b011 | format_type==3'b100)) ? rs2 : rs3;
    // data_mem_options_selection
    assign rw_data_mem = (format_type==3'b011) ? 1'b1 : 1'b0; // only 1 in S type instruction
    assign is_load_unsigned_data_mem = (format_type==3'b010 & funct3[2:1]==2'b10) ? 1'b1 : 1'b0; // only 1 in I type instruction and funct3= 4 o 5
    assign byte_half_word_data_mem = (funct3[1:0]==2'b00) ? 2'b10 : // funct3= 0 o 4 -byte
                                    ((funct3[1:0]==2'b01) ? 2'b01 : // funct3= 1 o 5 -half
                                                            2'b00); // funct3= 2     -word (default)
    // next_PC_selection
    assign jalr_pc = operand1+operand2;
    assign next_PC = ({format_type, branch_condition}==4'b100_1 | format_type==3'b110) ? PC+operand2 : // B | J
                    (({format_type, sub_format_type}==6'b010_011)                ? {jalr_pc[31:1], 1'b0} : // I (jalr)
                       PC+32'b100);                                                                    // Deafault
    // final_alu_fpu_res_selection
    assign EX_out = (({format_type, sub_format_type}==6'b000_000 & {funct7_out, funct3}!=7'b1011_000 & {funct7_out, funct3}!=7'b1100_000) | // se excluyen fmv.x.w y fmv.w.x
                                                                  format_type==3'b001) ? res_fpu    : // R (fp)   o R4
                   (({format_type, sub_format_type}==6'b000_000 & (funct7_out==4'b1011 | funct7_out==4'b1100)) ? operand1 : // fmv.x.w y fmv.w.x
                   (({format_type, sub_format_type}==6'b010_011 | format_type==3'b110) ? PC+32'b100 : // I (jalr) o J
                   ((format_type==3'b101)    ?   ( operand2 + (sub_format_type[0] ? PC : 32'b0) )   : // U
                        res_alu)));                                                                    // default 
    // mux rd
    assign rd = (format_type==3'b010 & ~sub_format_type[2] & ~sub_format_type[0]) ? data_out_data_mem : EX_out;
    // sub_decoder
    assign is_ecall  = (format_type==3'b010 & sub_format_type==3'b100 & operand2==32'b0) ? 1'b1 : 1'b0;
    assign is_ebreak = (format_type==3'b010 & sub_format_type==3'b100 & operand2==32'b1) ? 1'b1 : 1'b0;
    assign acces_to_fpu = (
            format_type==3'b001 | ( // R4
            {format_type, sub_format_type}==6'b0 & {funct7_out, funct3}!=7'b1011_000 & {funct7_out, funct3}!=7'b1100_000 ) // R (fp) - {fmv.x.w, fmv.w.x}
        ) ? 1'b1 : 1'b0;
    assign acces_to_mem = (format_type==3'b011 | (format_type==3'b010 & ~sub_format_type[2] & ~sub_format_type[0])) ? 1'b1 : 1'b0;
    assign not_valid = format_type==3'b111 ? 1'b1 : 1'b0;
    // FSM controller
    always_ff @(posedge(clk)) actual_state <= rst ? waiting_state : next_state;
    always_comb
        case (actual_state)
            default: begin                   // dafault
                {set_pc, set_inst, do_wb}        = 3'b000;
                {is_the_beginning, start_fpu}    = 2'b00;
                {valid_prog_mem, valid_data_mem} = 2'b00;
                {ready, exit_status}             = 3'b000;
                next_state = actual_state;
            end
            waiting_state: begin             // se espera señal de inicio "start"
                {set_pc, set_inst, do_wb}        = 3'b000;
                {is_the_beginning, start_fpu}    = 2'b00;
                {valid_prog_mem, valid_data_mem} = 2'b00;
                {ready, exit_status}             = 3'b000;
                next_state = start ? initial_state : waiting_state;
            end
            initial_state: begin             // se setea PC
                {set_pc, set_inst, do_wb}        = 3'b100;
                {is_the_beginning, start_fpu}    = 2'b10;
                {valid_prog_mem, valid_data_mem} = 2'b00;
                {ready, exit_status}             = 3'b000;
                next_state = program_loop_read_inst;
            end
            program_loop_read_inst: begin    // se lee nueva instrucción
                {set_pc, set_inst, do_wb}        = 3'b010;
                {is_the_beginning, start_fpu}    = 2'b00;
                {valid_prog_mem, valid_data_mem} = 2'b10;
                {ready, exit_status}             = 3'b000;
                next_state = out_of_range_prog_mem ? final_state : (ready_prog_mem ? program_loop_main : program_loop_read_inst);
            end
            program_loop_main: begin         // se setea y decodifica instrucción
                {set_pc, set_inst, do_wb}        = 3'b000;
                {is_the_beginning, start_fpu}    = 2'b00;
                {valid_prog_mem, valid_data_mem} = 2'b00;
                {ready, exit_status}             = 3'b000;
                next_state = (is_ecall | is_ebreak | not_valid) ? final_state :
                                                  (acces_to_fpu ? program_loop_fpu :
                                                  (acces_to_mem ? program_loop_mem : program_loop_new_pc_wb));
            end
            program_loop_fpu: begin          // se espera FPU
                {set_pc, set_inst, do_wb}        = 3'b000;
                {is_the_beginning, start_fpu}    = 2'b01;
                {valid_prog_mem, valid_data_mem} = 2'b00;
                {ready, exit_status}             = 3'b000;
                next_state = ready_fpu ? program_loop_new_pc_wb : program_loop_fpu;
            end
            program_loop_mem: begin          // se espera mem
                {set_pc, set_inst, do_wb}        = 3'b000;
                {is_the_beginning, start_fpu}    = 2'b00;
                {valid_prog_mem, valid_data_mem} = 2'b01;
                {ready, exit_status}             = 3'b000;
                next_state = out_of_range_data_mem ? final_state : (ready_data_mem ? program_loop_new_pc_wb : program_loop_mem);
            end
            program_loop_new_pc_wb: begin    // se setea new PC y realiza wb
                {set_pc, set_inst, do_wb}        = 3'b101;
                {is_the_beginning, valid_prog_mem} = 2'b0;
                start_fpu      = acces_to_fpu ? 1'b1 : 1'b0;
                valid_data_mem = acces_to_mem ? 1'b1 : 1'b0;
                {ready, exit_status}             = 3'b000;
                next_state = program_loop_read_inst;
            end
            final_state: begin               // se finaliza ejecución
                {set_pc, set_inst, do_wb}        = 3'b000;
                {is_the_beginning, start_fpu}    = 2'b00;
                {valid_prog_mem, valid_data_mem} = 2'b00;
                ready = 1'b1;
                exit_status = is_ecall                              ? 2'b00 : // 00 -> ecall
                            ( is_ebreak                             ? 2'b11 : // 11 -> ebreak
                            ( (out_of_range_prog_mem | not_valid)   ? 2'b01 : // 01 -> program out of range or not valid 
                            ( out_of_range_data_mem                 ? 2'b10 : // 10 -> memory out of range               
                              2'b00 )));
                next_state = start ? final_state : waiting_state;
            end
        endcase
    generic_register #(.width(32)) pc_register(
        .clk(clk), .reset(rst), .load(set_pc), .data_in(PC2reg),
        .data_out(PC)
    );
    generic_register #(.width(32)) inst_register(
        .clk(clk), .reset(rst), .load(set_inst), .data_in(inst2reg),
        .data_out(inst)
    );
    // prog_memory
    memory #(.initial_option(2)) prog_memory_unit(
        .clk(clk), .rst(1'b0),
        // inputs
        .rw(              (acces_to_prog_mem & ~start) ? prog_rw_fromEEI               : 1'b0),
        .valid(           (acces_to_prog_mem & ~start) ? prog_valid_mem_fromEEI        : valid_prog_mem),
        .addr(            (acces_to_prog_mem & ~start) ? prog_addr_fromEEI             : PC),
        .data_in(         (acces_to_prog_mem & ~start) ? prog_in_fromEEI               : 32'b0),
        .byte_half_word(  (acces_to_prog_mem & ~start) ? prog_byte_half_word_fromEEI   : 2'b0),
        .is_load_unsigned((acces_to_prog_mem & ~start) ? prog_is_load_unsigned_fromEEI : 1'b1),
        // outputs
        .ready(ready_prog_mem), .out_of_range(out_of_range_prog_mem), .data_out(inst2reg)
    );
    // data_memory
    memory #(.initial_option(1)) data_memory_unit(
        .clk(clk), .rst(1'b0),
        // inputs
        .rw(              (acces_to_data_mem & ~start) ? data_rw_fromEEI               : rw_data_mem),
        .valid(           (acces_to_data_mem & ~start) ? data_valid_mem_fromEEI        : valid_data_mem),
        .addr(            (acces_to_data_mem & ~start) ? data_addr_fromEEI             : EX_out),
        .data_in(         (acces_to_data_mem & ~start) ? data_in_fromEEI               : operand3),
        .byte_half_word(  (acces_to_data_mem & ~start) ? data_byte_half_word_fromEEI   : byte_half_word_data_mem),
        .is_load_unsigned((acces_to_data_mem & ~start) ? data_is_load_unsigned_fromEEI : is_load_unsigned_data_mem),
        // outputs
        .ready(ready_data_mem), .out_of_range(out_of_range_data_mem), .data_out(data_out_data_mem)
    );
    // Instruction_Decoder
    Instruction_Decoder Instruction_Decoder_unit(
        .in(inst),
        .is_imm_valid(is_imm_valid), .imm(imm),
        .rd_add(rd_add), .rs1_add(rs1_add), .rs2_add(rs2_add), .rs3_add(rs3_add),
        .funct7_out(funct7_out), .format_type(format_type), .sub_format_type(sub_format_type),
        .funct3(funct3), .funct2(funct2), .reg_access_option(reg_access_option)
    );
    // registers_files
    registers_files registers_files_unit(
        .clk(clk),
        // inputs
        .rs1_add( (acces_to_registers_files & ~start) ? rs1_add_fromEEI : rs1_add),
        .rs2_add( (acces_to_registers_files & ~start) ? rs2_add_fromEEI : rs2_add),
        .rs3_add(rs3_add),
        .wb_add(  (acces_to_registers_files & ~start) ? wb_add_fromEEI : rd_add),
        .wb_data( (acces_to_registers_files & ~start) ? wb_data_fromEEI : rd),
        .write_reg( (acces_to_registers_files & ~start) ? do_wb_fromEEI :
           ((format_type==3'b011 | format_type==3'b100) ? 1'b0 : do_wb) ),
        .is_wb_data_fp( (acces_to_registers_files & ~start) ? is_wb_data_fp_fromEEI : reg_access_option[0]),
        .is_rs1_fp( (acces_to_registers_files & ~start) ? is_rs1_fp_fromEEI : reg_access_option[1]),
        .is_rs2_fp( (acces_to_registers_files & ~start) ? is_rs2_fp_fromEEI : (reg_access_option[1] | reg_access_option[0])),
        // outputs
        .rs1(operand1), .rs2(rs2), .rs3(rs3)
    );
    // alu_op_selection
    alu_op_selection alu_op_selection_unit(
        .imm_11_5(operand2[11:5]), .funct7_out(funct7_out),
        .format_type(format_type), .sub_format_type(sub_format_type), .funct3(funct3),
        .alu_option(alu_option)
    );
    // ALU
    ALU ALU_unit(
        .in1(operand1), .in2( (format_type==3'b100) ? operand3 : operand2), // is B type?
        .operation(alu_option),
        .res(res_alu), .boolean_res(branch_condition)
    );
    // fpu_op_selection
    fpu_op_selection fpu_op_selection_unit(
        .rs2_add(rs2_add), .funct7_out(funct7_out),
        .format_type(format_type), .sub_format_type(sub_format_type), .funct3(funct3), .rm_from_fcsr(3'b000),
        .rm2fpu(rm2fpu), .fpu_option(fpu_option)
    );
    // FPU
    FPU FPU_unit(
        .start(start_fpu), .rst(rst), .clk(clk), .rm(rm2fpu),
        .option(fpu_option), .in1(operand1), .in2(operand2), .in3(operand3),
        .NV(ignored_flags[4]), .NX(ignored_flags[3]), .UF(ignored_flags[2]), .OF(ignored_flags[1]), .DZ(ignored_flags[0]),
        .ready(ready_fpu), .out(res_fpu)
    );
endmodule