/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021
*/
`timescale 1ns / 1ps

module fp_converter(
    input start, rst, clk, integer_is_signed, option, //option: 0 -> Integer to fp | 1 -> fp to Integer
    input [2:0] rm,
    input [31:0] in,
    output NV, NX, ready,// NV: invalid operation NX: inexact
    output [31:0] out
    /*
    rm =
        000 -> RNE: To nearest, ties to even
        001 -> RTZ: Toward 0
        010 -> RDN: Toward -inf
        011 -> RUP: Toward +inf
        100 -> RMM: To nearest, ties away from zero
    */
    );
    typedef enum {waiting_state,
                  initial_state,
                  pre_iteration_state_1,
                  pre_iteration_state_2,
                  iteration_state_1,
                  iteration_state_2,
                  iteration_state_3,
                  pre_final_state_1,
                  pre_final_state_2,
                  final_state
    } state_type;
    state_type actual_state, next_state;
    reg sel, set, reset, start_norm, ready_from_controller;
    wire start_ctrl, exception_flag, norm_ready, fp_sig, still_norm, NX_fp2, NX_2fp, NX_check;
    wire [7:0] initial_fp_exp, exp_to_normalizer, exp_from_reg, exp_from_norm, exp_from_rounder;
    wire [31:0] integer_res, fp_res, exception_res, initial_fp_man, man_to_normalizer,
         man_from_reg, man_from_norm, man_from_rounder;
    assign start_ctrl = option ? 1'b0 : start;
    assign ready = (option | exception_flag) ? start : ready_from_controller;
    assign out = exception_flag ? exception_res : (option ? integer_res : fp_res);
    assign {exp_to_normalizer, man_to_normalizer} = sel ? {exp_from_reg, man_from_reg} : {initial_fp_exp, initial_fp_man};
    assign fp_res = {fp_sig, exp_from_reg, man_from_reg[30:8]};
    assign NX = ( (NX_fp2 & option) | (NX_2fp & ~option) | NX_check) ? 1'b1 : 1'b0;
    // FSM
    always_ff @(posedge(clk)) actual_state <= rst ? waiting_state : next_state;
    always_comb begin
        case(actual_state)
            default: begin
                {sel, set, reset, start_norm, ready_from_controller} = 5'b00000;
                next_state = actual_state;
            end
            waiting_state: begin
                {sel, set, reset, start_norm, ready_from_controller} = 5'b00100;
                next_state = start_ctrl ? initial_state : waiting_state;
            end
            initial_state: begin
                {sel, set, reset, start_norm, ready_from_controller} = 5'b00010;
                next_state = norm_ready ? (still_norm ? pre_final_state_1 : pre_iteration_state_1) : initial_state;
            end
            pre_iteration_state_1: begin
                {sel, set, reset, start_norm, ready_from_controller} = 5'b01010;
                next_state = pre_iteration_state_2;
            end
            pre_iteration_state_2: begin
                {sel, set, reset, start_norm, ready_from_controller} = 5'b10000;
                next_state = iteration_state_1;
            end
            iteration_state_1: begin
                {sel, set, reset, start_norm, ready_from_controller} = 5'b10010;
                next_state = norm_ready ? (still_norm ? pre_final_state_2 : iteration_state_2) : iteration_state_1;
            end
            iteration_state_2: begin
                {sel, set, reset, start_norm, ready_from_controller} = 5'b11010;
                next_state = iteration_state_3;
            end
            iteration_state_3: begin
                {sel, set, reset, start_norm, ready_from_controller} = 5'b10000;
                next_state = iteration_state_1;
            end
            pre_final_state_1: begin
                {sel, set, reset, start_norm, ready_from_controller} = 5'b01010;
                next_state = final_state;
            end
            pre_final_state_2: begin
                {sel, set, reset, start_norm, ready_from_controller} = 5'b11010;
                next_state = final_state;
            end
            final_state: begin
                {sel, set, reset, start_norm, ready_from_controller} = 5'b00001;
                next_state = start_ctrl ? final_state : waiting_state;
            end
        endcase
    end
    converter_exceptions_checker converter_exceptions_checker_module(
        .integer_is_signed(integer_is_signed), .option(option), .rm(rm), .in(in),
        .exception_flag(exception_flag), .invalid_flag(NV), .inexact_flag(NX_check), .exception_res(exception_res)
    );
    fp_to_integer_unit fp_to_integer_unit_module(
        .integer_is_signed(integer_is_signed), .rm(rm), .fp_in(in),
        .NX(NX_fp2), .integer_out(integer_res)
    );
    integer_to_fp_unit integer_to_fp_unit_module(
        .integer_is_signed(integer_is_signed), .integer_in(in),
        .sig_out(fp_sig), .exp_out(initial_fp_exp), .man_out(initial_fp_man)
    );
    normalizer_integer2fp normalizer_integer2fp_module(
        .start(start_norm), .rst(rst), .clk(clk), .exp_in(exp_to_normalizer), .man_in(man_to_normalizer),
        .ready(norm_ready), .exp_out(exp_from_norm), .man_out(man_from_norm)
    );
    rounder_integer2fp rounder_integer2fp_module(
        .sig_in(fp_sig), .rm(rm), .exp_in(exp_from_norm), .man_in(man_from_norm),
        .still_norm(still_norm), .NX(NX_2fp), .exp_out(exp_from_rounder), .man_out(man_from_rounder)
    );
    generic_register #(40) converter_register(
        .clk(clk), .reset(reset), .load(set), .data_in({exp_from_rounder, man_from_rounder}),
        .data_out({exp_from_reg, man_from_reg})
    );
endmodule

module converter_exceptions_checker(
    input integer_is_signed, option,
    input [2:0] rm,
    input [31:0] in,
    output reg exception_flag, invalid_flag, inexact_flag,
    output [31:0] exception_res
    );
    reg [2:0] sel;
    wire in_as_fp_is_nan, in_as_fp_is_zero, exp_lt_0, exp_gt_30, exp_gt_31, in_is_zeros, in_is_ones;
    assign in_as_fp_is_nan = (in[30:23]==8'b11111111 & in[22:0]!=23'b0) ? 1'b1 : 1'b0;
    assign in_as_fp_is_zero = (in[30:0]==31'b0) ? 1'b1 : 1'b0;
    assign exp_lt_0  = (unsigned'(in[30:23])<unsigned'(8'b01111111)) ? 1'b1 : 1'b0;
    assign exp_gt_30 = (unsigned'(in[30:23])>unsigned'(8'b10011101)) ? 1'b1 : 1'b0;
    assign exp_gt_31 = (unsigned'(in[30:23])>unsigned'(8'b10011110)) ? 1'b1 : 1'b0;
    assign in_is_zeros = (in==32'b0) ? 1'b1 : 1'b0;
    assign in_is_ones = (in==32'b11111111111111111111111111111111) ? 1'b1 : 1'b0;
    assign invalid_flag = (option & ( in_as_fp_is_nan | (integer_is_signed & exp_gt_30) | (~integer_is_signed & (exp_gt_31 | in[31]) ) )) ? 1'b1 : 1'b0;
    assign inexact_flag = option & exp_lt_0;
    // Opciones de salidas triviales
    assign exception_res = (sel==3'b000) ? 32'b10000000000000000000000000000000 : // (signed) -2³¹ = fp(-0)
                           (sel==3'b001) ? 32'b01111111111111111111111111111111 : // (signed) 2³¹-1
                           (sel==3'b010) ? 32'b11111111111111111111111111111111 : // (unsigned) 2³²-1 = (signed) -1
                           (sel==3'b011) ? 32'b10111111100000000000000000000000 : // fp(-1)
                           (sel==3'b100) ? 32'b00000000000000000000000000000000 : // (un/signed) 0 = fp(+0)
                           (sel==3'b101) ? 32'b00000000000000000000000000000001 : // (un/signed) 1
                           32'bX;
    always_comb
        if(option) // fp2integer
            if(in_as_fp_is_zero) {sel, exception_flag} = {3'b100, 1'b1};
            else if(in_as_fp_is_nan) {sel, exception_flag} = {(integer_is_signed ? 3'b001 : 3'b010), 1'b1};
            else if(exp_lt_0)
                case(rm)
                    3'b010:  {sel, exception_flag} = {((integer_is_signed & in[31]) ? 3'b010 : 3'b100), 1'b1};  // RDN
                    3'b011:  {sel, exception_flag} = {(in[31] ? 3'b100 : 3'b101), 1'b1};                        // RUP
                    3'b001:  {sel, exception_flag} = {3'b100, 1'b1};                                            // RTZ
                    default: {sel, exception_flag} = {( (unsigned'(in[30:23])==unsigned'(8'b01111110)) ?
                        (in[31] ? (integer_is_signed ? 3'b010 : 3'b100) : 3'b101) : 3'b100 ), 1'b1};            // RNE - RMM
                endcase
            else if(integer_is_signed) {sel, exception_flag} = exp_gt_30 ? {(in[31] ? 3'b000 : 3'b001), 1'b1} : {3'bX, 1'b0};
            else {sel, exception_flag} = in[31] ? {3'b100, 1'b1} : (exp_gt_31 ? {3'b010, 1'b1} : {3'bX , 1'b0} ); // integer_is_signed=0
        else begin // integer2fp
            sel = in_is_zeros ? 3'b100 : ((integer_is_signed & in_is_ones) ? 3'b011 : 3'bX);
            exception_flag = (in_is_zeros | (integer_is_signed & in_is_ones)) ? 1'b1 : 1'b0;
        end
endmodule

module fp_to_integer_unit(
    input integer_is_signed,
    input [2:0] rm,
    input [31:0] fp_in,
    output NX,
    output [31:0] integer_out
    );
    wire [54:0] from_shifter;
    wire [31:0] interger_rounded;
    assign from_shifter = {32'b1, fp_in[22:0]} << unsigned'(fp_in[30:23]) - unsigned'(8'b01111111); 
    assign integer_out = (integer_is_signed & fp_in[31]) ? ~interger_rounded+32'b1 : interger_rounded;
    integer_rounder integer_rounder_unit(
        .is_signed(integer_is_signed), .sig_in(fp_in[31]), .rm(rm), .integer_in(from_shifter),
        .NX(NX), .integer_out(interger_rounded)
    );
endmodule

module integer_rounder(
    input is_signed, sig_in,
    input [2:0] rm,
    input [54:0] integer_in,
    output NX,
    output [31:0] integer_out
    );
    reg sel;
    wire sticky, is_overflow;
    wire [2:0] rounding_bits;
    wire [32:0] temp_out; // se añade bit en caso de overflow para unsigned integer
    // Se obtienen rounding bits
    assign sticky = (integer_in[20:0] != 0) ? 1'b1 : 1'b0;
    assign rounding_bits = {integer_in[22:21], sticky};
    // Salida falg NX
    assign NX = (rounding_bits == 3'b0) ? 1'b0 : 1'b1;
    // Se redondea
    assign temp_out = sel ? {1'b0, integer_in[54:23]}+33'b1 : {1'b0, integer_in[54:23]};
    // Se checkea overflow según si es signed o no
    assign is_overflow = is_signed ? (temp_out[32:31]!=2'b0 ? 1'b1 : 1'b0)
                                   : (temp_out[ 32 ] !=1'b0 ? 1'b1 : 1'b0);
    // Se obtiene resultado final
    assign integer_out = is_overflow ?
            (is_signed ? 32'b01111111111111111111111111111111 : 32'b11111111111111111111111111111111)
            : temp_out[31:0];
    // Logica combinacional de redondeo
    always_comb
        case(rounding_bits) // grs
            3'b000: sel = 1'b0;
            default: case(rm)
                    3'b000: sel = (rounding_bits[1:0]==2'b0) ? (integer_in[23] ? 1'b1 : 1'b0) : // RNE
                                    (rounding_bits[2] ? 1'b1 : 1'b0);   
                    3'b001: sel = 1'b0;                                                         // RTZ
                    3'b010: sel =  sig_in ? 1'b1 : 1'b0;                                        // RDN
                    3'b011: sel = ~sig_in ? 1'b1 : 1'b0;                                        // RUP
                    3'b100: sel = (rounding_bits[1:0]==2'b0) ? 1'b1 :                           // RMM
                                    (rounding_bits[2] ? 1'b1 : 1'b0); 
                    default: sel = 1'b0;
                endcase
        endcase
endmodule

module integer_to_fp_unit(
    input integer_is_signed,
    input [31:0] integer_in,
    output sig_out,
    output [7:0] exp_out,
    output [31:0] man_out
    );
    assign sig_out = (integer_is_signed & (signed'(integer_in)<0)) ? 1'b1 : 1'b0;
    assign exp_out = 8'b10011110; // = 158 = 127+31
    assign man_out = sig_out ? ~integer_in+32'b1 : integer_in;
endmodule

module normalizer_integer2fp( 
    // Input
    input start, rst, clk,
    input [7:0] exp_in,
    input [31:0] man_in,
    // Output
    output reg ready,
    output [7:0] exp_out,
    output [31:0] man_out
    );
    typedef enum {
        waiting_state, initial_state, iteration_state, final_state
    } state_type;
    state_type actual_state, next_state;
    reg sel, set, reset;
    wire done;
    wire [7:0] new_exp;
    wire [31:0] new_man;
    wire [39:0] to_reg;
    assign done = (man_out[31] == 1'b1 | man_out == 0) ? 1'b1 : 1'b0;
    assign new_exp = unsigned'(exp_out) - unsigned'(8'b1);
    assign new_man = man_out << 1;
    assign to_reg = sel ? {new_exp, new_man} : {exp_in, man_in};
    // FSM
    always_ff @(posedge(clk)) actual_state <= rst ? waiting_state : next_state;
    always_comb begin
        case(actual_state)
            default: begin
                {sel, set, reset, ready} = 4'b0000;
                next_state = actual_state;
            end
            waiting_state: begin
                {sel, set, reset, ready} = 4'b0010;
                next_state = start ? initial_state : waiting_state;
            end
            initial_state: begin
                {sel, set, reset, ready} = 4'b0100;
                next_state = done ? final_state : iteration_state;
            end
            iteration_state: begin
                {sel, set, reset, ready} = 4'b1100;
                next_state = done ? final_state : iteration_state;
            end
            final_state: begin
                {sel, set, reset, ready} = 4'b0001;
                next_state = start ? final_state : waiting_state;        
            end
        endcase
    end
    // registers
    generic_register #(40) register_out_unit(
        .clk(clk), .reset(reset), .load(set), .data_in(to_reg),
        .data_out({exp_out, man_out})
    );
endmodule

module rounder_integer2fp(
    input sig_in,
    input [2:0] rm,
    input [7:0] exp_in,
    input [31:0] man_in,
    /*
    rm =
        000 -> RNE: To nearest, ties to even
        001 -> RTZ: Toward 0
        010 -> RDN: Toward -inf
        011 -> RUP: Toward +inf
        100 -> RMM: To nearest, ties away from zero
    */
    output still_norm, NX,
    output [7:0] exp_out,
    output [31:0] man_out
    );
    reg sel;
    wire sticky;
    wire [2:0] grs;
    wire [32:0] temp;
    assign exp_out = temp[32] ? unsigned'(exp_in)+8'b1 : exp_in;
    assign sticky = (man_in[5:0] != 6'b0) ? 1'b1 : 1'b0;
    assign grs = {man_in[7:6], sticky};
    assign NX = (grs != 3'b0) ? 1'b1 : 1'b0;
    assign still_norm = (man_out[31]==1'b1 | man_out==0) ? 1'b1 : 1'b0; 
    assign man_out = temp[32] ? temp[32:1] : temp[31:0];
    assign temp = sel ? {1'b0, man_in}+33'b100000000 : {1'b0, man_in};
    always_comb
        case(grs) // grs
            3'b000: sel = 1'b0;
            default: case(rm)
                    3'b000: sel = (grs[1:0]==2'b0) ? (man_in[8] ? 1'b1 : 1'b0) : // RNE: To nearest, ties to even
                                                    (grs[2] ? 1'b1 : 1'b0);   
                    3'b001: sel = 1'b0;                                          // RTZ: Toward 0
                    3'b010: sel =  sig_in ? 1'b1 : 1'b0;                         // RDN: Toward -inf
                    3'b011: sel = ~sig_in ? 1'b1 : 1'b0;                         // RUP: Toward +inf
                    3'b100: sel = (grs[1:0]==2'b0) ? (1'b1) :                    // RMM: To nearest, ties away from zero
                                                    (grs[2] ? 1'b1 : 1'b0); 
                    default: sel = 1'b0;
                endcase
        endcase
endmodule