/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021
*/
`timescale 1ns / 1ps
// set_param pwropt.maxFaninFanoutToNetRatio 1000
module TOP(
    input clk, rst_asin, start_asin, resume_asin, // rst, start, resume deben ser pulsadores (OJO, en todo el resto del diseño start se comporta de otra forma)
    input [15:0] in,
    output [5:0] color_leds,
    output [15:0] leds, display
    );
    typedef enum {
        waiting_state,
        final_state_error_prog, final_state_error_data, start_cpu_state,
        ebreak_state, ecall_state, ecall_default_state,
        ecall_print_integer_state, ecall_print_fp_state,
        ecall_get_integer_state_1, ecall_get_integer_state_2, ecall_get_integer_state_3,
        ecall_get_fp_state_1, ecall_get_fp_state_2, ecall_get_fp_state_3,
        final_state
    } state_type;
    state_type actual_state, next_state; 
    reg rst_PC, set_PC, set_first_input_half, set_second_input_half,
        start_to_cpu, sel_info_out, enable_info_out,
        acces_to_registers_files, is_fp, do_wb_fromEEI, rst_riscv;
    reg [3:0] info_state; 
    reg [1:0] input_indicator;
    /*
        input_indicator =
            00 o 11 - no input indicator
            01 - first half indicator
            10 - second half indicator
        exit_status[1:0] =
            00 -> ecall     (se lee registro x17 y según eso se toma decición)
            11 -> ebreak    (pausa ejecución)
            01 -> program out of range
            10 -> memory out of range
    */
    wire ready, prog_ready_toEEI, prog_out_of_range_toEEI, data_ready_toEEI, data_out_of_range_toEEI, rst, start, resume;
    wire [1:0] exit_status;
    wire [15:0] second_input_half, first_input_half;
    wire [31:0] prog_out_toEEI, data_out_toEEI, rs1_toEEI, rs2_toEEI, PC, PC_reg, info_out, input_from_user;
    assign info_out = enable_info_out ? (sel_info_out ? rs2_toEEI : PC_reg) : 32'b0;
    assign input_from_user = {second_input_half, first_input_half};
    assign leds = (input_indicator[1]^input_indicator[0]) ? in : 16'b0;
    // color_leds_decoder
    assign color_leds =  (input_indicator==2'b01 & info_state==4'h8) ? 6'b000_101 : // get integer (PURPLE)
                        ((input_indicator==2'b10 & info_state==4'h8) ? 6'b101_000 : // get integer (PURPLE)
                        ((input_indicator==2'b01 & info_state==4'h9) ? 6'b000_110 : // get fp (YELLOW)
                        ((input_indicator==2'b10 & info_state==4'h9) ? 6'b110_000 : // get fp (YELLOW)
                       ((info_state==4'h0) ? 6'b001_001 : // A -> --B|--B = BLUE     - waiting state
                       ((info_state==4'h2) ? 6'b011_011 : // B -> -GB|-GB = CYAN     - cpu working
                       ((info_state==4'h3) ? 6'b111_111 : // C -> RGB|RGB = WHITE    - ebreak
                       ((info_state==4'h4) ? 6'b100_001 : // D -> R--|--B = RED/BLUE - prog error
                       ((info_state==4'h5) ? 6'b001_100 : // E -> --B|R-- = BLUE/RED - data error
                       ((info_state==4'h6) ? 6'b101_101 : // F -> R-B|R-B = PURPLE   - print integer
                       ((info_state==4'h7) ? 6'b110_110 : // G -> RG-|RG- = YELLOW   - print fp
                       ((info_state==4'h8) ? 6'b000_000 : // H -> ---|--- = NO COLOR - get integer
                       ((info_state==4'h9) ? 6'b000_000 : // I -> ---|--- = NO COLOR - get fp
                       ((info_state==4'hA) ? 6'b010_010 : // J -> -G-|-G- = GREEN    - final state
                       ((info_state==4'hB) ? 6'b100_100 : // K -> R--|R-- = RED      - ecall default
                     6'b000_000))))))))))))));//rgb_rgb
    // FSM controller
    always_ff @(posedge(clk)) actual_state <= rst ? waiting_state : next_state;
    always_comb
        case (actual_state)
            default: begin
                {input_indicator, info_state}                    = 6'b00_0000; // A
                {set_first_input_half, set_second_input_half}    = 2'b00;
                {sel_info_out, enable_info_out}                  = 2'b00;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b000;
                {rst_riscv, start_to_cpu, set_PC, rst_PC}        = 4'b00_00;
                next_state = actual_state;
            end
            waiting_state: begin
                {input_indicator, info_state}                    = 6'b00_0000; // A
                {set_first_input_half, set_second_input_half}    = 2'b00;
                {sel_info_out, enable_info_out}                  = 2'b00;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b000;
                {rst_riscv, start_to_cpu, set_PC, rst_PC}        = 4'b10_01;
                next_state = start ? start_cpu_state : waiting_state;
            end
            start_cpu_state: begin
                {input_indicator, info_state}                    = 6'b00_0010; // B
                {set_first_input_half, set_second_input_half}    = 2'b00;
                {sel_info_out, enable_info_out}                  = 2'b00;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b000;
                {rst_riscv, start_to_cpu, rst_PC} = 3'b01_0; set_PC = ready;
                next_state = ready ? ((exit_status == 2'b11) ? ebreak_state : 
                                     ((exit_status == 2'b01) ? final_state_error_prog : 
                                     ((exit_status == 2'b10) ? final_state_error_data : 
                                     ecall_state))) : start_cpu_state;
            end
            ebreak_state: begin
                {input_indicator, info_state}                    = 6'b00_0011; // C
                {set_first_input_half, set_second_input_half}    = 2'b00;
                {sel_info_out, enable_info_out}                  = 2'b01;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b000;
                {rst_riscv, start_to_cpu, set_PC, rst_PC}        = {resume, 3'b0_00};
                next_state = resume ? start_cpu_state : ebreak_state;
            end
            final_state_error_prog: begin
                {input_indicator, info_state}                    = 6'b00_0100; // D
                {set_first_input_half, set_second_input_half}    = 2'b00;
                {sel_info_out, enable_info_out}                  = 2'b01;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b000;
                {rst_riscv, start_to_cpu, set_PC, rst_PC}        = 4'b00_00;
                next_state = resume ? waiting_state : final_state_error_prog;
            end
            final_state_error_data: begin
                {input_indicator, info_state}                    = 6'b00_0101; // E
                {set_first_input_half, set_second_input_half}    = 2'b00;
                {sel_info_out, enable_info_out}                  = 2'b01;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b000;
                {rst_riscv, start_to_cpu, set_PC, rst_PC}        = 4'b00_00;
                next_state = resume ? waiting_state : final_state_error_data;
            end
            ecall_print_integer_state: begin
                {input_indicator, info_state}                    = 6'b00_0110; // F
                {set_first_input_half, set_second_input_half}    = 2'b00;
                {sel_info_out, enable_info_out}                  = 2'b11;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b100;
                {rst_riscv, start_to_cpu, set_PC, rst_PC}        = {resume, 3'b0_00};
                next_state = resume ? start_cpu_state : ecall_print_integer_state;
            end
            ecall_print_fp_state: begin
                {input_indicator, info_state}                    = 6'b00_0111; // G
                {set_first_input_half, set_second_input_half}    = 2'b00;
                {sel_info_out, enable_info_out}                  = 2'b11;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b110;
                {rst_riscv, start_to_cpu, set_PC, rst_PC}        = {resume, 3'b0_00};
                next_state = resume ? start_cpu_state : ecall_print_fp_state;
            end
            ecall_get_integer_state_1: begin
                {input_indicator, info_state}                    = 6'b01_1000; // H
                {set_first_input_half, set_second_input_half}    = 2'b10;
                {sel_info_out, enable_info_out}                  = 2'b00;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b100;
                {rst_riscv, start_to_cpu, set_PC, rst_PC}        = 4'b00_00;
                next_state = start ? ecall_get_integer_state_2 : ecall_get_integer_state_1;
            end
            ecall_get_integer_state_2: begin
                {input_indicator, info_state}                    = 6'b10_1000; // H
                {set_first_input_half, set_second_input_half}    = 2'b01;
                {sel_info_out, enable_info_out}                  = 2'b00;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b100;
                {rst_riscv, start_to_cpu, set_PC, rst_PC}        = 4'b00_00;
                next_state = resume ? ecall_get_integer_state_3 : ecall_get_integer_state_2;
            end
            ecall_get_integer_state_3: begin
                {input_indicator, info_state}                    = 6'b00_1000; // H
                {set_first_input_half, set_second_input_half}    = 2'b00;
                {sel_info_out, enable_info_out}                  = 2'b00;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b101;
                {rst_riscv, start_to_cpu, set_PC, rst_PC}        = 4'b10_00;
                next_state = start_cpu_state;
            end
            ecall_get_fp_state_1: begin
                {input_indicator, info_state}                    = 6'b01_1001; // I
                {set_first_input_half, set_second_input_half}    = 2'b10;
                {sel_info_out, enable_info_out}                  = 2'b00;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b110;
                {rst_riscv, start_to_cpu, set_PC, rst_PC}        = 4'b00_00;
                next_state = start ? ecall_get_fp_state_2 : ecall_get_fp_state_1;
            end
            ecall_get_fp_state_2: begin
                {input_indicator, info_state}                    = 6'b10_1001; // I
                {set_first_input_half, set_second_input_half}    = 2'b01;
                {sel_info_out, enable_info_out}                  = 2'b00;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b110;
                {rst_riscv, start_to_cpu, set_PC, rst_PC}        = 4'b00_00;
                next_state = resume ? ecall_get_fp_state_3 : ecall_get_fp_state_2;
            end
            ecall_get_fp_state_3: begin
                {input_indicator, info_state}                    = 6'b00_1001; // I
                {set_first_input_half, set_second_input_half}    = 2'b00;
                {sel_info_out, enable_info_out}                  = 2'b00;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b111;
                {rst_riscv, start_to_cpu, set_PC, rst_PC}        = 4'b10_00;
                next_state = start_cpu_state;
            end
            final_state: begin
                {input_indicator, info_state}                    = 6'b00_1010; // J
                {set_first_input_half, set_second_input_half}    = 2'b00;
                {sel_info_out, enable_info_out}                  = 2'b01;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b000;
                {rst_riscv, start_to_cpu, set_PC, rst_PC}        = 4'b00_00;
                next_state = resume ? waiting_state : final_state;
            end
            ecall_state: begin
                {input_indicator, info_state}                    = 6'b00_1011; // K
                {set_first_input_half, set_second_input_half}    = 2'b00;
                {sel_info_out, enable_info_out}                  = 2'b00;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b100;
                {rst_riscv, start_to_cpu, set_PC, rst_PC}        = 4'b00_00;
                next_state = (rs1_toEEI==31'b01010) ? final_state : 
                            ((rs1_toEEI==31'b00001) ? ecall_print_integer_state : 
                            ((rs1_toEEI==31'b00010) ? ecall_print_fp_state : 
                            ((rs1_toEEI==31'b00101) ? ecall_get_integer_state_1 : 
                            ((rs1_toEEI==31'b00110) ? ecall_get_fp_state_1 : 
                                ecall_default_state))));
            end
            ecall_default_state: begin
                {input_indicator, info_state}                    = 6'b00_1011; // K
                {set_first_input_half, set_second_input_half}    = 2'b00;
                {sel_info_out, enable_info_out}                  = 2'b01;
                {acces_to_registers_files, is_fp, do_wb_fromEEI} = 3'b000;
                {rst_riscv, start_to_cpu, set_PC, rst_PC}        = {resume, 3'b0_00};
                next_state = resume ? start_cpu_state : ecall_default_state;
            end
        endcase
    //riscv32imf_singlecycle
    riscv32imf_pipeline
    riscv32imf(
        // inputs
        .clk(clk), .rst(rst | rst_riscv), .start(start_to_cpu), .acces_to_registers_files(acces_to_registers_files),
        .is_wb_data_fp_fromEEI(is_fp), .do_wb_fromEEI(do_wb_fromEEI),
        .is_rs1_fp_fromEEI(1'b0), .is_rs2_fp_fromEEI(is_fp),
        .acces_to_prog_mem(1'b0), .prog_rw_fromEEI(1'b0),
        .prog_valid_mem_fromEEI(1'b0), .prog_is_load_unsigned_fromEEI(1'b0),
        .acces_to_data_mem(1'b0), .data_rw_fromEEI(1'b0),
        .data_valid_mem_fromEEI(1'b0), .data_is_load_unsigned_fromEEI(1'b0),
        .initial_PC(PC_reg),
        .prog_addr_fromEEI(32'b0), .prog_in_fromEEI(32'b0),
        .data_addr_fromEEI(32'b0), .data_in_fromEEI(32'b0),
        .wb_data_fromEEI(input_from_user),
        .prog_byte_half_word_fromEEI(2'b00), .data_byte_half_word_fromEEI(2'b00),
        .rs1_add_fromEEI(5'b10001), .rs2_add_fromEEI(5'b01010), .wb_add_fromEEI(5'b01010),
        // outputs
        .ready(ready),
        .prog_ready_toEEI(prog_ready_toEEI), .prog_out_of_range_toEEI(prog_out_of_range_toEEI),
        .data_ready_toEEI(data_ready_toEEI), .data_out_of_range_toEEI(data_out_of_range_toEEI),
        .exit_status(exit_status),
        .prog_out_toEEI(prog_out_toEEI), .data_out_toEEI(data_out_toEEI), .rs1_toEEI(rs1_toEEI), .rs2_toEEI(rs2_toEEI), .PC(PC)
    );
    generic_register #(.width(32)) PC_in_reg(
        .clk(clk), .reset(rst_PC), .load(set_PC), .data_in(PC+32'b100),
        .data_out(PC_reg)
    );
    generic_register #(.width(16)) first_input_half_reg(
        .clk(clk), .reset(1'b0), .load(set_first_input_half), .data_in(in),
        .data_out(first_input_half)
    );
    generic_register #(.width(16)) second_input_half_reg(
        .clk(clk), .reset(1'b0), .load(set_second_input_half), .data_in(in),
        .data_out(second_input_half)
    );
    debounce rst_debounce   (.clk(clk), .signal_in(~rst_asin),   .signal_out(rst));
    debounce start_debounce (.clk(clk), .signal_in(start_asin),  .signal_out(start));
    debounce resume_debounce(.clk(clk), .signal_in(resume_asin), .signal_out(resume));
    full_display full_display_unit(
        .clk(clk), .enable( (input_indicator[1]^input_indicator[0]) | enable_info_out ),
        .show_options(input_indicator), .in( (input_indicator[1]^input_indicator[0]) ? {in, in} : info_out ),
        .out(display)
    );
endmodule

module generic_register #(parameter width=32)(
    input clk, reset, load,
    input [width-1:0] data_in,
    output reg[width-1:0] data_out
    );
    always_ff @(negedge clk) data_out <= load ? data_in : (reset ? 0 : data_out);
endmodule

module debounce(input clk, signal_in, output reg signal_out);
    typedef enum {
        waiting_state, counter_state, hold_state, response_state
    } state_type;
    state_type actual_state, next_state;
    reg signal_in_sync, start_counter, counter_ready;
    reg [15:0] counter;
    always_ff @(posedge clk) {signal_in_sync, actual_state} <= {signal_in, next_state}; // Señal de entrada sincronizada y actualización de estado
    always_ff @(posedge clk) // debounce counter
        if(start_counter) {counter, counter_ready} <= {counter + 16'b1,  (counter == 16'hFFFF) ? 1'b1 : 1'b0};
        else              {counter, counter_ready} <= 17'b0;
    always_comb // FSM controller
        case (actual_state)
            default: begin
                {start_counter, signal_out} = 2'b00;
                next_state = actual_state;
            end
            waiting_state: begin
                {start_counter, signal_out} = 2'b00;
                next_state = signal_in_sync ? counter_state : waiting_state;
            end
            counter_state: begin
                {start_counter, signal_out} = 2'b10;
                next_state = signal_in_sync ? (counter_ready ? hold_state : counter_state) : waiting_state;
            end
            hold_state: begin
                {start_counter, signal_out} = 2'b00;
                next_state = signal_in_sync ? hold_state : response_state;
            end
            response_state: begin
                {start_counter, signal_out} = 2'b01;
                next_state = waiting_state;
            end
        endcase
endmodule

module full_display(
    input clk, enable,
    input [1:0] show_options,
    input [31:0] in,
    output [15:0] out // enable7, enable6, enable5, enable4, enable3, enable2, enable1, enable0, CA, CB, CC, CD, CE, CF, CG, DP
    );
    /*
        show_options =
                00 o 11 -> full: 8 bytes
                01      -> half: first 4 bytes
                10      -> half: last 4 bytes
    */
    reg [2:0] select;
    reg [15:0] counter;
    wire show_first_half, show_last_half;
    wire [7:0] character0, character1, character2, character3, character4, character5, character6, character7;
    assign {show_first_half, show_last_half} = {(show_options==2'b10) ? 1'b0 : 1'b1, (show_options==2'b01) ? 1'b0 : 1'b1};
    assign out = enable ? 
                ((select==3'h0) ? {show_first_half ? 8'b11111110 : 8'hFF, character0} : 
                ((select==3'h1) ? {show_first_half ? 8'b11111101 : 8'hFF, character1} : 
                ((select==3'h2) ? {show_first_half ? 8'b11111011 : 8'hFF, character2} : 
                ((select==3'h3) ? {show_first_half ? 8'b11110111 : 8'hFF, character3} : 
                ((select==3'h4) ? {show_last_half  ? 8'b11101111 : 8'hFF, character4} : 
                ((select==3'h5) ? {show_last_half  ? 8'b11011111 : 8'hFF, character5} : 
                ((select==3'h6) ? {show_last_half  ? 8'b10111111 : 8'hFF, character6} : 
                ((select==3'h7) ? {show_last_half  ? 8'b01111111 : 8'hFF, character7} : 
                    16'hFFFF)))))))) : 16'hFFFF;
    always_ff @(posedge clk) 
        if(enable) begin
            if(counter==16'hFFFF) {select, counter} = { unsigned'(select)+3'b1, 16'b0 };
            else {select, counter} = { select, unsigned'(counter)+16'b1 };
        end
        else {select, counter} = 0;
    display_character display_character_unit0(
        .in(in[ 3: 0]), .out(character0) // CA, CB, CC, CD, CE, CF, CG, DP
    );
    display_character display_character_unit1(
        .in(in[ 7: 4]), .out(character1) // CA, CB, CC, CD, CE, CF, CG, DP
    );
    display_character display_character_unit2(
        .in(in[11: 8]), .out(character2) // CA, CB, CC, CD, CE, CF, CG, DP
    );
    display_character display_character_unit3(
        .in(in[15:12]), .out(character3) // CA, CB, CC, CD, CE, CF, CG, DP
    );
    display_character display_character_unit4(
        .in(in[19:16]), .out(character4) // CA, CB, CC, CD, CE, CF, CG, DP
    );
    display_character display_character_unit5(
        .in(in[23:20]), .out(character5) // CA, CB, CC, CD, CE, CF, CG, DP
    );
    display_character display_character_unit6(
        .in(in[27:24]), .out(character6) // CA, CB, CC, CD, CE, CF, CG, DP
    );
    display_character display_character_unit7(
        .in(in[31:28]), .out(character7) // CA, CB, CC, CD, CE, CF, CG, DP
    );
endmodule

module display_character(
    input [3:0] in,
    output [7:0] out // CA, CB, CC, CD, CE, CF, CG, DP
    ); // Dot On (0 lógico) => letra | Dot Off (1 lógico) => número
    assign out = (in==4'h0) ? 8'b00000011 : // 0
                ((in==4'h1) ? 8'b10011111 : // 1
                ((in==4'h2) ? 8'b00100101 : // 2
                ((in==4'h3) ? 8'b00001101 : // 3
                ((in==4'h4) ? 8'b10011001 : // 4
                ((in==4'h5) ? 8'b01001001 : // 5
                ((in==4'h6) ? 8'b01000001 : // 6
                ((in==4'h7) ? 8'b00011111 : // 7
                ((in==4'h8) ? 8'b00000001 : // 8
                ((in==4'h9) ? 8'b00001001 : // 9
                ((in==4'hA) ? 8'b00010000 : // A
                ((in==4'hB) ? 8'b00000000 : // B
                ((in==4'hC) ? 8'b01100010 : // C 
                ((in==4'hD) ? 8'b00000010 : // D
                ((in==4'hE) ? 8'b01100000 : // E
                ((in==4'hF) ? 8'b01110000 : // F
                7'b1111111))))))))))))))); // default
endmodule