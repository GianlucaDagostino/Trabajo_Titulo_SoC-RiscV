/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021
*/
`timescale 1ns / 1ps

/****************  Top module: begin  ****************/
module fp_arithmetic_unit(
    input start, rst, clk, // start: Need to be on til the op is ready
    input [2:0] op, rm,
    input [31:0] in1, in2,
    /*
        op =
            000 -> in1+in2   ADD
            001 -> in1*in2   MUL
            010 -> in1/in2   DIV
            011 -> sqrt(in1) SQRT
            100 -> in1-in2   SUB
            101 -> -in1*in2  -MUL
            110 -> -in1/in2  -DIV
        rm =
            000 -> RNE
            001 -> RTZ
            010 -> RDN
            011 -> RUP
            100 -> RMM
    */
    output reg ready, // On when the operation is ready
    output reg [2:0] status,
    output [31:0] out
    /*
        status =
            000 -> no flag
            101 -> no flag
            110 -> no flag
            --------------
            001 -> UF flag
            010 -> OF flag
            011 -> NV flag
            100 -> DZ flag
            111 -> NX flag
    */
    );
    typedef enum {
        waiting_state,
        initial_state,
        pre_iteration_state,
        iteration_state_1,
        iteration_state_2,
        iteration_state_3,
        exception_state_1,
        exception_state_2,
        exception_state_3,
        final_exception_state,
        pre_final_state_1,
        pre_final_state_2,
        final_state
    } state_type;
    state_type actual_state, next_state;
    reg sel, set, start_norm;
    reg [2:0] sel_out;
    wire sig1, sig2, sig, sig_from_adder, start_to_ctrl, ready_from_checker, ready_from_norm, ready_from_add, ready_from_mul, ready_from_div, ready_from_sqrt, still_norm, inexact_flag, check_flag, is_normal, is_uf, is_of, is_desnorm;
    wire [1:0] status_from_norm;
    wire [2:0] status_checker, sel_out_checker;
    wire [7:0] exp1, exp2, exp_to_norm, exp_from_reg, exp_from_adder, exp_from_mul, exp_from_div, exp_from_sqrt, exp_from_norm;
    wire [27:0] man1, man2, man_to_norm, man_from_reg, man_from_adder, man_from_mul, man_from_div, man_from_sqrt, man_from_norm, man_from_rounder;
    // Obtaining full inputs: input_decoder
    assign sig2 = op[2] ? ~in2[31] : in2[31];
    assign {sig1, exp1,     exp2,           man1[27], man2[27],     man1[25:0],          man2[25:0]} 
         = {in1[31:23],     in2[30:23],     2'b0,                   in1[22:0], 3'b0,     in2[22:0], 3'b0};
    assign man1[26] = (exp1 == 8'b0) ? 1'b0 : 1'b1;
    assign man2[26] = (exp2 == 8'b0) ? 1'b0 : 1'b1;
    // Mux inputs to normalizer
    assign {exp_to_norm, man_to_norm} = sel ? {exp_from_reg, man_from_reg} :
                                        ((op[1:0] == 2'b00) ? {exp_from_adder, man_from_adder} : // add
                                        ((op[1:0] == 2'b01) ? {exp_from_mul, man_from_mul} :     // mul
                                        ((op[1:0] == 2'b10) ? {exp_from_div, man_from_div} :     // div
                                        ((op[1:0] == 2'b11) ? {exp_from_sqrt, man_from_sqrt} :   // sqrt
                                        36'bX))));
    // Mux start to controller
    assign start_to_ctrl = ((op[1:0] == 2'b00) ? ((ready_from_add  | ~check_flag) * ready_from_checker) :  // add
                           ((op[1:0] == 2'b01) ? ((ready_from_mul  | ~check_flag) * ready_from_checker) :  // mul
                           ((op[1:0] == 2'b10) ? ((ready_from_div  | ~check_flag) * ready_from_checker) :  // div
                           ((op[1:0] == 2'b11) ? ((ready_from_sqrt | ~check_flag) * ready_from_checker) :  // sqrt
                            1'bx))));
    // Mux sig
    assign sig = (op[1:0] == 2'b00) ? sig_from_adder : // add
                ((op[1:0] == 2'b11) ? 1'b0 :           // sqrt
                  sig1^sig2);                          // mul or div
    // OUT
    assign out = (sel_out == 3'b000) ? {sig, exp_from_reg, man_from_reg[25:3]} :    // final res no trivial
                ((sel_out == 3'b001) ? in1 :                                        // final in1
                ((sel_out == 3'b010) ? {sig2, in2[30:0]} :                          // final in2
                ((sel_out == 3'b100) ? {sig, 31'b0} :                               // final Zero
                ((sel_out == 3'b101) ? {sig, 31'b1} :                               // final almost Zero
                ((sel_out == 3'b110) ? {sig, 8'b11111111, 23'b0} :                  // final Inf
                ((sel_out == 3'b011) ? {sig, 31'b1111111011111111111111111111111} : // final almost Inf
                ((sel_out == 3'b111) ? {sig, 9'b111111111, 22'b0} :                 // final NaN
                  32'bX)))))));
    // control flags (inputs) for FSM
    assign check_flag = (sel_out_checker == 3'b000) ? 1'b1 : 1'b0; // no trivial res
    assign is_normal = (status_from_norm == 2'b00) ? 1'b1 : 1'b0;  // normal res
    assign is_uf = (status_from_norm == 2'b01) ? 1'b1 : 1'b0;      // UF flag res
    assign is_of = (status_from_norm == 2'b10) ? 1'b1 : 1'b0;      // OF flag res
    assign is_desnorm= (status_from_norm == 2'b11) ? 1'b1 : 1'b0;  // res desnormalized
    // FSM
    always_ff @(posedge(clk)) actual_state <= rst ? waiting_state : next_state;
    always_comb begin
        case(actual_state)
            default: begin
                {sel, set, start_norm} = 3'b000;
                {sel_out, status, ready} = {3'b000, 3'b000, 1'b0};
                next_state = actual_state;
            end
            waiting_state: begin
                {sel, set, start_norm} = 3'b000;
                {sel_out, status, ready} = {3'b000, 3'b000, 1'b0};
                next_state = start_to_ctrl ? (check_flag ? initial_state : exception_state_1) : waiting_state;
            end
            initial_state: begin
                {sel, set, start_norm} = 3'b001;
                {sel_out, status, ready} = {3'b000, 3'b000, 1'b0};
                next_state = ready_from_norm ? (is_normal ? (still_norm ? pre_final_state_1 : pre_iteration_state) : exception_state_2) : initial_state;
            end
            pre_iteration_state: begin
                {sel, set, start_norm} = 3'b011;
                {sel_out, status, ready} = {3'b000, 3'b000, 1'b0};
                next_state = iteration_state_1;
            end
            iteration_state_1: begin
                {sel, set, start_norm} = 3'b100;
                {sel_out, status, ready} = {3'b000, 3'b000, 1'b0};
                next_state = iteration_state_2;
            end
            iteration_state_2: begin
                {sel, set, start_norm} = 3'b101;
                {sel_out, status, ready} = {3'b000, 3'b000, 1'b0};
                next_state = ready_from_norm ? (is_normal ? (still_norm ? pre_final_state_2 : iteration_state_3) : exception_state_3) : iteration_state_2;
            end
            iteration_state_3: begin
                {sel, set, start_norm} = 3'b111;
                {sel_out, status, ready} = {3'b000, 3'b000, 1'b0};
                next_state = iteration_state_1;
            end
            exception_state_1: begin
                {sel, set, start_norm} = 3'b000;
                {sel_out, status, ready} = {sel_out_checker, status_checker, 1'b1};
                next_state = start ? exception_state_1 : waiting_state;
            end
            exception_state_2: begin
                {sel, set, start_norm} = 3'b011;
                {sel_out, status, ready} = {3'b000, 3'b000, 1'b0};
                next_state = final_exception_state;
            end
            exception_state_3: begin
                {sel, set, start_norm} = 3'b111;
                {sel_out, status, ready} = {3'b000, 3'b000, 1'b0};
                next_state = final_exception_state;
            end
            final_exception_state: begin
                {sel, set, start_norm} = 3'b000; ready = 1'b1;
                if(is_desnorm) {sel_out, status} = {3'b000, 3'b001}; // desnorm => uf => NX
                else if(is_of) begin
                    // OF flag - "inf" or "almost inf"
                    status = 3'b010;
                    sel_out = (rm == 3'b001) ? 3'b011 :                   // RTZ
                             ((rm == 3'b010) ? ( sig ? 3'b110 : 3'b011) : // RDN
                             ((rm == 3'b011) ? (~sig ? 3'b110 : 3'b011) : // RUP
                             3'b110));                                    // RNE - RMM
                end
                else if(is_uf) begin
                    // Uf flag - "zero" or "almost zero"
                    status = 3'b001;
                    sel_out = (rm == 3'b001) ? 3'b100 :                   // RTZ
                             ((rm == 3'b010) ? ( sig ? 3'b101 : 3'b100) : // RDN
                             ((rm == 3'b011) ? (~sig ? 3'b101 : 3'b100) : // RUP
                             3'b100));                                    // RNE - RMM
                end
                else {sel_out, status} = 6'bX;
                next_state = start ? final_exception_state : waiting_state;
            end
            pre_final_state_1: begin
                {sel, set, start_norm} = 3'b011;
                {sel_out, status, ready} = {3'b000, 3'b000, 1'b0};
                next_state = final_state;
            end
            pre_final_state_2: begin
                {sel, set, start_norm} = 3'b111;
                {sel_out, status, ready} = {3'b000, 3'b000, 1'b0};
                next_state = final_state;
            end
            final_state: begin
                {sel, set, start_norm} = 3'b000;
                {sel_out, ready} = {3'b000, 1'b1};
                status = inexact_flag ? 3'b111 : 3'b000;
                next_state = start ? final_state : waiting_state;
            end
        endcase
    end
    /***  Registers  ***/
    generic_register #(.width(36)) res_register(
        .clk(clk), .reset(1'b0), .load(set), .data_in({exp_from_norm, man_from_rounder}),
        .data_out({exp_from_reg, man_from_reg})
    );
    /***  Normalizer and Rounder  ***/
    NORMALIZER normalizer_unit(
        .start(start_norm), .rst(rst), .clk(clk), .exp_in(exp_to_norm), .man_in(man_to_norm),
        .ready(ready_from_norm), .status(status_from_norm), .exp_out(exp_from_norm), .man_out(man_from_norm)
    );
    ROUNDER rounder_unit(
        .rm(rm), .sig_in(sig), .man_in(man_from_norm),
        .still_norm(still_norm), .inexact_flag(inexact_flag), .man_out(man_from_rounder)
    );
    /***  Exceptions and trivial cases checker  ***/
    excep_triv_checker excep_triv_checker_unit(
        .start(start), .clk(clk), .rm(rm), .op(op[1:0]), .sig1(sig1), .sig2(sig2), .exp1(exp1), .exp2(exp2), .frac1(man1[26:3]), .frac2(man2[26:3]),
        .ready(ready_from_checker), .status_out(status_checker), .sel_out(sel_out_checker)
    );
    /***  Arithmetic Units  ***/
    ADDER adder_unit(
        .start(start), .clk(clk), .sig1(sig1), .sig2(sig2), .exp1(exp1), .exp2(exp2), .man1(man1), .man2(man2),
        .ready(ready_from_add), .sig_out(sig_from_adder), .exp_out(exp_from_adder), .man_out(man_from_adder)
    );
    MULTIPLIER multiplier_unit(
        .start(start), .clk(clk), .exp1(exp1), .exp2(exp2), .man1(man1), .man2(man2),
        .ready(ready_from_mul), .exp_out(exp_from_mul), .man_out(man_from_mul)
    );
    DIVISOR divisor_unit(
        .start(start), .rst(rst), .clk(clk), .exp1(exp1), .exp2(exp2), .man1(man1), .man2(man2),
        .ready(ready_from_div), .exp_out(exp_from_div), .man_out(man_from_div)
    );
    SQRT sqrt_unit(
        .start(start), .rst(rst), .clk(clk), .exp_in(exp1), .man_in(man1),
        .ready(ready_from_sqrt), .exp_out(exp_from_sqrt), .man_out(man_from_sqrt)
    );
endmodule
/*****************  Top module: end  *****************/

/**********  Normalizer and Rounder: begin  **********/
module NORMALIZER(
    input start, rst, clk,
    input [7:0] exp_in,
    input [27:0] man_in,
    output reg ready,
    output [1:0] status,
    output [7:0] exp_out,
    output [27:0] man_out
    /*
        status = 
            00 -> normalized
            01 -> UF
            10 -> OF
            11 -> desnormalized
    */
    );
    typedef enum {
        waiting_state, initial_state, iteration_state, final_state
    } state_type;
    state_type actual_state, next_state;
    reg sel, set;
    wire done, exp_valid;
    wire [7:0] new_exp, exp_to_reg;
    wire [27:0] new_man, man_to_reg, desp_man_izq, temp_man_out;
    // flags
    assign done      = (temp_man_out[27:26] == 2'b01) ? 1 : 0;
    assign exp_valid = (status         == 2'b00) ? 1 : 0;
    // new normalized value
    assign new_exp = (temp_man_out[27] == 1'b1) ? (unsigned'(exp_out)+unsigned'(8'b1)) :
                    ((temp_man_out[26] == 1'b0) ? (unsigned'(exp_out)-unsigned'(8'b1)) : exp_out);
    assign new_man = (temp_man_out[27] == 1'b1) ? (temp_man_out[0] ? {(temp_man_out[27:1] >> 1), temp_man_out[0]} : (temp_man_out >> 1)) :
                    ((temp_man_out[26] == 1'b0) ? (temp_man_out << 1) : temp_man_out);
    // mux to register
    assign {exp_to_reg, man_to_reg} = sel ? {new_exp, new_man} : {exp_in, man_in};
    // status out
    assign status = (exp_out==8'b11111111 & (man_in[27] | man_in[26])) ? 2'b10 : 
                   ((exp_out==8'b0) ? ((temp_man_out[27:1]==27'b0) ? 2'b01 : 2'b11) : 2'b00);
    assign man_out = (exp_out==8'b0 & done) ? (temp_man_out>>1) : temp_man_out;
    // FSM
    always_ff @(posedge(clk)) actual_state <= rst ? waiting_state : next_state;
    always_comb begin
        case(actual_state)
            default: begin
                {sel, set, ready} = 3'b000;
                next_state = actual_state;
            end
            waiting_state: begin
                {sel, set, ready} = 3'b000;
                next_state = start ? initial_state : waiting_state;
            end
            initial_state: begin
                {sel, set, ready} = 3'b010;
                next_state = exp_valid ? (done ? final_state : iteration_state) : final_state;
            end
            iteration_state: begin
                {sel, set, ready} = 3'b110;
                next_state = exp_valid ? (done ? final_state : iteration_state) : final_state;
            end
            final_state: begin
                {sel, set, ready} = 3'b001;
                next_state = start ? final_state : waiting_state;        
            end
        endcase
    end
    // register
    generic_register #(.width(36)) register_out_unit(
        .clk(clk), .reset(1'b0), .load(set), .data_in({exp_to_reg, man_to_reg}),
        .data_out({exp_out, temp_man_out})
    );
endmodule

module ROUNDER(
    input [2:0] rm,
    input sig_in,
    input [27:0] man_in,
    /*
        rm =
            000 -> RNE
            001 -> RTZ
            010 -> RDN
            011 -> RUP
            100 -> RMM
    */
    output still_norm, inexact_flag,
    output [27:0] man_out
    );
    reg sel;
    assign inexact_flag = (man_in[2:0] != 3'b0) ? 1'b1 : 1'b0;
    assign still_norm = (man_out[27:26]==2'b01) ? 1'b1 : 1'b0;
    assign man_out = sel ? {man_in[27:3], 3'b0}+28'b1000 : {man_in[27:3], 3'b0};
    always_comb
        case(man_in[2:0]) // grs
            3'b000: sel = 1'b0;
            default: case(rm)
                    3'b000: sel = (man_in[1:0]==2'b0) ? (man_in[3] ? 1'b1 : 1'b0) : // RNE
                                                    ((man_in[2] ? 1'b1 : 1'b0));   
                    3'b001: sel = 1'b0;                                             // RTZ
                    3'b010: sel =  sig_in ? 1'b1 : 1'b0;                            // RDN
                    3'b011: sel = ~sig_in ? 1'b1 : 1'b0;                            // RUP
                    3'b100: sel = (man_in[1:0]==2'b0) ? (1'b1) :                    // RMM
                                                    ((man_in[2] ? 1'b1 : 1'b0)); 
                    default: sel = 1'b0;
                endcase
        endcase
endmodule
/**********  Normalizer and Rounder: end  ************/

/**********  Arithmetic Units: begin  ****************/
/*------------------ ADDER BEGIN --------------------*/
module ADDER(
    input start, clk,
    input sig1, sig2,
    input [7:0] exp1, exp2,
    input [27:0] man1, man2,
    output ready,
    output sig_out,
    output [7:0] exp_out,
    output [27:0] man_out
    );
    wire ready1, ready2, shift1;
    wire [1:0] add_op;
    wire [7:0] temp_exp_out;
    wire [9:0] exp_difference;
    wire [4:0] offset1, offset2;
    wire [26:0] man1_normalized, man2_normalized;
    wire [27:0] man_to_shifter, man_from_shifter, man_no_shifted, temp_man_out;
    assign ready = (ready1 & ready2) ? 1'b1 : 1'b0;
    //Comparador de exponentes
    assign shift1 = ((signed'({2'b0, exp1})-signed'({5'b0, offset1}))<(signed'({2'b0, exp2})-signed'({5'b0, offset2}))) ? 1 : 0;
    // Restador de exponentes
    assign exp_difference = {exp1,exp2}==0 ? 0 : (shift1 ? ((signed'({2'b0, exp2})-signed'({5'b0, offset2}))-(signed'({2'b0, exp1})-signed'({5'b0, offset1}))) : ((signed'({2'b0, exp1})-signed'({5'b0, offset1}))-(signed'({2'b0, exp2})-signed'({5'b0, offset2}))));
    // Identificador de operación
    assign add_op = shift1 ? {sig1, sig2} : {sig2, sig1};
    // Mux to shifter
    assign man_to_shifter =  shift1 ? ({exp1,exp2}==0 ? man1 : {1'b0, man1_normalized}) : ({exp1,exp2}==0 ? man2 : {1'b0, man2_normalized});
    // Man direct to adder
    assign man_no_shifted = ~shift1 ? ({exp1,exp2}==0 ? man1 : {1'b0, man1_normalized}) : ({exp1,exp2}==0 ? man2 : {1'b0, man2_normalized});
    // Outputs
    assign temp_exp_out = {exp1,exp2}==0 ? 0 : (~shift1 ? exp1-offset1 : exp2-offset2);
    assign exp_out = (temp_exp_out==0 & temp_man_out[27:26]!=2'b0) ? 8'b1 : temp_exp_out;
    assign man_out = (temp_exp_out==0 & temp_man_out[27:26]!=2'b0) ? (
                        temp_man_out[27] ? (temp_man_out>>1) : temp_man_out
                    ) : temp_man_out;
    shifter_right shifter_right_unit(
        .exp_difference(exp_difference), .man_input(man_to_shifter),
        .man_output(man_from_shifter)
    );
    significands_adder significands_adder_unit(
        .add_op(add_op), .man_in_1(man_from_shifter), .man_in_2(man_no_shifted),
        .sig_r(sig_out), .man_output(temp_man_out)
    );
    normalizer4significands_inputs normalizer4significands_inputs_adder1(
        .start(start), .clk(clk), .man_in(man1[26:0]),
        .ready(ready1), .man_out(man1_normalized), .offset(offset1)
    );
    normalizer4significands_inputs normalizer4significands_inputs_adder2(
        .start(start), .clk(clk), .man_in(man2[26:0]),
        .ready(ready2), .man_out(man2_normalized), .offset(offset2)
    );
endmodule

module shifter_right(
    input[9:0] exp_difference,
    input[27:0] man_input,
    output[27:0] man_output
    );
    wire[49:0] temp;
    wire sticky;
    assign temp = {man_input, 22'b0} >> signed'(exp_difference);
    assign sticky = (temp[22:0] != 0 || exp_difference >= 26) ? 1 : 0;
    assign man_output = {temp[49:23], sticky};
endmodule

module significands_adder(
    input [1:0] add_op,
    input [27:0] man_in_1, man_in_2,
    output reg sig_r,
    output [27:0] man_output
    );
    reg[27:0] temp;
    wire sticky;
    assign sticky = (man_in_1[0] || man_in_2[0] || temp[0]) ? 1 : 0; // Manteniendo el sticky bit
    assign man_output = {temp[27:1], sticky}; // Mantisa de salida
    always_comb
        case(add_op) // add_op = {signo mantisa desplazada (man_in_1), signo mantisa no desplazada (man_in_2)}
            2'b00: begin
                temp = unsigned'(man_in_2) + unsigned'(man_in_1);
                sig_r = 0;
            end
            2'b01:
                if(man_in_1 >= man_in_2) begin
                    temp = unsigned'(man_in_1) - unsigned'(man_in_2);
                    sig_r = 0;
                end
                else begin
                    temp = unsigned'(man_in_2) - unsigned'(man_in_1);
                    sig_r = 1;
                end
            2'b10:
                if(man_in_2 >= man_in_1) begin
                    temp = unsigned'(man_in_2) - unsigned'(man_in_1);
                    sig_r = 0;
                end
                else begin
                    temp = unsigned'(man_in_1) - unsigned'(man_in_2);
                    sig_r = 1;
                end
            2'b11: begin
                temp = unsigned'(man_in_2) + unsigned'(man_in_1);
                sig_r = 1;
            end
        endcase 
endmodule
/*------------------  ADDER END  --------------------*/

/*--------------- MULTIPLIER BEGIN ------------------*/
module MULTIPLIER(
    input start, clk,
    input [7:0] exp1, exp2,
    input [27:0] man1, man2,
    output ready,
    output [7:0] exp_out,
    output [27:0] man_out
    );
    wire ready1, ready2;
    wire [9:0] temp_exp;
    wire [26:0] man1_normalized, man2_normalized;
    wire [55:0] temp_man1, temp2_man;
    wire [4:0] desp, offset1, offset2;
    assign ready = (ready1 & ready2) ? 1'b1 : 1'b0;
    assign temp_exp =signed'({2'b0, exp1})+signed'({2'b0, exp2})-signed'({5'b0, offset1})-signed'({5'b0, offset2})-signed'(10'b0001111111)+signed'({5'b0, desp});
    assign exp_out = (signed'(temp_exp)<signed'(0)) ? 8'b0 :                      // Desnorm - UF
                    ((signed'(temp_exp)==signed'(0) & temp_man1[55]) ? 8'b1 :     // NX
                    ((signed'(temp_exp)>=signed'(10'b0011111111)) ? 8'b11111111 : // OF
                    temp_exp[7:0]));                                              // normal case
    assign temp2_man = (unsigned'(temp_man1) >> (~unsigned'(temp_exp)+unsigned'(10'b10)));
    assign man_out = (signed'(temp_exp)<signed'(0)) ? {temp2_man[55:29], ((temp2_man[28:0] != 29'b0) ? 1'b1 : 1'b0)} :                        // Desnorm - UF
                    ((signed'(temp_exp)==signed'(0) & temp_man1[55]) ? {1'b0, temp_man1[55:30], ((temp_man1[29:0] != 29'b0) ? 1'b1 : 1'b0)} : // NX
                    ((signed'(temp_exp)>=signed'(10'b0011111111)) ? 28'b0 :                                                                   // OF
                    {temp_man1[55:29], ((temp_man1[28:0] != 29'b0) ? 1'b1 : 1'b0)}));
    significands_multiplier man_multiplier(
        .man_in_1({1'b0, man1_normalized}), .man_in_2({1'b0, man2_normalized}), .previus_desp2rigth(5'b0),
        .man_output(temp_man1[55:28]), .actual_desp2rigth(desp)
    );
    normalizer4significands_inputs normalizer4significands_inputs_multiplier1(
        .start(start), .clk(clk), .man_in(man1[26:0]),
        .ready(ready1), .man_out(man1_normalized), .offset(offset1)
    );
    normalizer4significands_inputs normalizer4significands_inputs_multiplier2(
        .start(start), .clk(clk), .man_in(man2[26:0]),
        .ready(ready2), .man_out(man2_normalized), .offset(offset2)
    );
endmodule

module significands_multiplier( // man_in_1 * man_in_2
    input [4:0] previus_desp2rigth,
    input [27:0] man_in_1, man_in_2,
    output [4:0] actual_desp2rigth,
    output [27:0] man_output
    );
    wire[55:0] temp;
    wire sticky;
    assign temp = 56'(unsigned'(man_in_1)*unsigned'(man_in_2));
    assign sticky = (temp[55] | temp[54]) ? ((temp[28:0] != 29'b0) ? 1 : 0) : ((temp[26:0] != 27'b0) ? 1 : 0) ;
    assign actual_desp2rigth = (temp[55] | temp[54]) ? (unsigned'(previus_desp2rigth)+unsigned'(5'b10)) : previus_desp2rigth;
    assign man_output = (temp[55] | temp[54]) ? ({temp[55:29], sticky}) : ({temp[53:27], sticky});
endmodule
/*---------------  MULTIPLIER END  ------------------*/

/*----------------- DIVISOR BEGIN -------------------*/
module DIVISOR(    
    input start, rst, clk,
    input [7:0] exp1, exp2,
    input [27:0] man1, man2,
    output ready,
    output [7:0] exp_out,
    output [27:0] man_out
    );
    wire sticky;
    wire [9:0] temp_exp;
    wire [55:0] temp_man1, temp2_man;
    wire [4:0] dividend_offset, divisor_offset;
    assign temp_exp =signed'({2'b0, exp1})-signed'({5'b0, dividend_offset})-signed'({2'b0, exp2})+signed'({5'b0, divisor_offset})+signed'(10'b0001111111);
    assign exp_out = (signed'(temp_exp)<=signed'(0)) ? 8'b0 :                                     // Desnorm - UF
                    ((signed'(temp_exp)>=signed'(10'b0011111111) & temp_man1[54]) ? 8'b11111111 : // OF
                    temp_exp[7:0]);                                                               // normal case
    assign temp2_man = (unsigned'(temp_man1) >> (~unsigned'(temp_exp)+unsigned'(10'b10)));
    assign sticky = (temp2_man[28:0] != 29'b0) ? 1'b1 : 1'b0;
    assign man_out = (signed'(temp_exp)<=signed'(0)) ? {temp2_man[55:29], sticky} :               // Desnorm - UF
                    (  (signed'(temp_exp)>=signed'(10'b0011111111)  & temp_man1[54] ) ? 28'b0 :   // OF
                    temp_man1[55:28]);                                                            // normal case
    assign {temp_man1[55], temp_man1[27:0]} = 29'b0;
    significands_divisor significands_divisor_unit(
        .start(start), .rst(rst), .clk(clk),
        .dividend(man1[26:0]), .divisor(man2[26:0]),
        .ready(ready), .man_output(temp_man1[54:28]),
        .dividend_offset(dividend_offset), .divisor_offset(divisor_offset)
    );
endmodule

module significands_divisor (
    input start, rst, clk,
    input [26:0] dividend, divisor, // dividend/divisor=quotient or quotient*divisor+remaimder=dividend
    output reg ready,
    output [26:0] man_output, // bit_0, bit_-1, ..., bit_-23, bit_g, bit_r, bit_s
    output [4:0] dividend_offset, divisor_offset
    );
    typedef enum {
        waiting_state,
        initial_state,
        middle_state,
        iteration_state_1,
        iteration_state_2a1,
        iteration_state_2a2,
        iteration_state_2b1,
        iteration_state_2b2,
        iteration_state_3,
        final_state
    } state_type;
    state_type actual_state, next_state;
    reg sel_divisor, set_divisor, sel_remainder, set_remainder, sel_op,
        sel_quotient, set_quotient, rst_quotient, set_counter, rst_counter;
    wire dividend_ready, divisor_ready, count_flag, remainder_is_ltzero, sticky;
    wire [4:0] to_counter_reg, from_counter_reg;
    wire [26:0] dividend_normalized, divisor_normalized,
                to_quotient_reg, from_quotient_reg,
                to_divisor_reg, from_divisor_reg;
    wire [28:0] to_remainder_reg, from_remainder_reg;
    assign to_divisor_reg = sel_divisor ? (from_divisor_reg>>1) : divisor_normalized;
    assign to_remainder_reg = sel_remainder ? (
        (sel_op) ? (signed'(from_remainder_reg)+signed'({2'b0, from_divisor_reg})) : // sel_op=1 -> rr=rr+dd
                   (signed'(from_remainder_reg)-signed'({2'b0, from_divisor_reg}))   // sel_op=0 -> rr=rr-dd
        ) : {2'b0, dividend_normalized};
    assign to_quotient_reg = sel_quotient ? (unsigned'((from_quotient_reg<<1))+unsigned'(27'b1)) : (from_quotient_reg<<1);
    assign to_counter_reg = (unsigned'(from_counter_reg)+unsigned'(5'b1));
    assign count_flag = (unsigned'(from_counter_reg)==unsigned'(27)) ? 1'b1 : 1'b0;
    assign remainder_is_ltzero = (signed'(from_remainder_reg)<signed'(29'b0)) ? 1'b1 : 1'b0;
    assign sticky = ((from_quotient_reg[0]==1'b1 | to_remainder_reg!=29'b0) ? 1'b1 : 1'b0);
    assign man_output = {from_quotient_reg[26:1], sticky}; // se mantiene sticky
    // FSM
    always_ff @(posedge(clk)) actual_state <= rst ? waiting_state : next_state;
    always_comb
        case(actual_state)
            default: begin
                {sel_divisor, set_divisor}                 = 2'b00;  // divisor controls
                {sel_remainder, set_remainder}             = 2'b00;  // remainder controls
                {sel_quotient, set_quotient, rst_quotient} = 3'b000; // quotient controls
                {set_counter, rst_counter}                 = 2'b00;  // counter controls
                {sel_op, ready}                            = 2'b00;  // alu_op and ready signals
                next_state = actual_state;
            end
            waiting_state: begin
                {sel_divisor, set_divisor}                 = 2'b00;  // divisor controls
                {sel_remainder, set_remainder}             = 2'b00;  // remainder controls
                {sel_quotient, set_quotient, rst_quotient} = 3'b000; // quotient controls
                {set_counter, rst_counter}                 = 2'b00;  // counter controls
                {sel_op, ready}                            = 2'b00;  // alu_op and ready signals
                next_state = (start & dividend_ready & divisor_ready) ? initial_state : waiting_state;
            end
            initial_state: begin
                {sel_divisor, set_divisor}                 = 2'b01;  // divisor controls
                {sel_remainder, set_remainder}             = 2'b01;  // remainder controls
                {sel_quotient, set_quotient, rst_quotient} = 3'b001; // quotient controls
                {set_counter, rst_counter}                 = 2'b01;  // counter controls
                {sel_op, ready}                            = 2'b00;  // alu_op and ready signals
                next_state = middle_state;
            end
            middle_state: begin
                {sel_divisor, set_divisor}                 = 2'b10;  // divisor controls
                {sel_remainder, set_remainder}             = 2'b10;  // remainder controls
                {sel_quotient, set_quotient, rst_quotient} = 3'b000; // quotient controls
                {set_counter, rst_counter}                 = 2'b00;  // counter controls
                {sel_op, ready}                            = 2'b00;  // alu_op and ready signals
                next_state = iteration_state_1;
            end
            iteration_state_1: begin
                {sel_divisor, set_divisor}                 = 2'b10;  // divisor controls
                {sel_remainder, set_remainder}             = 2'b11;  // remainder controls
                {sel_quotient, set_quotient, rst_quotient} = 3'b000; // quotient controls
                {set_counter, rst_counter}                 = 2'b10;  // counter controls
                {sel_op, ready}                            = 2'b00;  // alu_op and ready signals
                next_state = remainder_is_ltzero ? iteration_state_2b1 : iteration_state_2a1;
            end
            iteration_state_2a1: begin
                {sel_divisor, set_divisor}                 = 2'b10;  // divisor controls
                {sel_remainder, set_remainder}             = 2'b10;  // remainder controls
                {sel_quotient, set_quotient, rst_quotient} = 3'b100; // quotient controls
                {set_counter, rst_counter}                 = 2'b00;  // counter controls
                {sel_op, ready}                            = 2'b00;  // alu_op and ready signals
                next_state = iteration_state_2a2;
            end
            iteration_state_2a2: begin
                {sel_divisor, set_divisor}                 = 2'b10;  // divisor controls
                {sel_remainder, set_remainder}             = 2'b10;  // remainder controls
                {sel_quotient, set_quotient, rst_quotient} = 3'b110; // quotient controls
                {set_counter, rst_counter}                 = 2'b00;  // counter controls
                {sel_op, ready}                            = 2'b00;  // alu_op and ready signals
                next_state = iteration_state_3;
            end
            iteration_state_2b1: begin
                {sel_divisor, set_divisor}                 = 2'b10;  // divisor controls
                {sel_remainder, set_remainder}             = 2'b10;  // remainder controls
                {sel_quotient, set_quotient, rst_quotient} = 3'b010; // quotient controls
                {set_counter, rst_counter}                 = 2'b00;  // counter controls
                {sel_op, ready}                            = 2'b10;  // alu_op and ready signals
                next_state = iteration_state_2b2;
            end
            iteration_state_2b2: begin
                {sel_divisor, set_divisor}                 = 2'b10;  // divisor controls
                {sel_remainder, set_remainder}             = 2'b11;  // remainder controls
                {sel_quotient, set_quotient, rst_quotient} = 3'b000; // quotient controls
                {set_counter, rst_counter}                 = 2'b00;  // counter controls
                {sel_op, ready}                            = 2'b10;  // alu_op and ready signals
                next_state = iteration_state_3;
            end
            iteration_state_3: begin
                {sel_divisor, set_divisor}                 = 2'b11;  // divisor controls
                {sel_remainder, set_remainder}             = 2'b10;  // remainder controls
                {sel_quotient, set_quotient, rst_quotient} = 3'b000; // quotient controls
                {set_counter, rst_counter}                 = 2'b00;  // counter controls
                {sel_op, ready}                            = 2'b00;  // alu_op and ready signals
                next_state = count_flag ? final_state : iteration_state_1;
            end
            final_state: begin
                {sel_divisor, set_divisor}                 = 2'b00;  // divisor controls
                {sel_remainder, set_remainder}             = 2'b00;  // remainder controls
                {sel_quotient, set_quotient, rst_quotient} = 3'b000; // quotient controls
                {set_counter, rst_counter}                 = 2'b00;  // counter controls
                {sel_op, ready}                            = 2'b01;  // alu_op and ready signals
                next_state = start ? final_state : waiting_state;
            end
        endcase  
    generic_register #(.width(29)) remainder_register(
        .clk(clk), .reset(1'b0), .load(set_remainder), .data_in(to_remainder_reg),
        .data_out(from_remainder_reg)
    );
    generic_register #(.width(27)) divisor_register(
        .clk(clk), .reset(1'b0), .load(set_divisor), .data_in(to_divisor_reg),
        .data_out(from_divisor_reg)
    );
    generic_register #(.width(27)) quotient_register(
        .clk(clk), .reset(rst_quotient), .load(set_quotient), .data_in(to_quotient_reg),
        .data_out(from_quotient_reg)
    );
    generic_register #(.width(5)) counter_register(
        .clk(clk), .reset(rst_counter), .load(set_counter), .data_in(to_counter_reg),
        .data_out(from_counter_reg)
    );
    normalizer4significands_inputs normalizer4significands_inputs_divisor_4dividend(
        .start(start), .clk(clk), .man_in(dividend),
        .ready(dividend_ready), .man_out(dividend_normalized), .offset(dividend_offset)
    );
    normalizer4significands_inputs normalizer4significands_inputs_divisor_4divisor(
        .start(start), .clk(clk), .man_in(divisor),
        .ready(divisor_ready), .man_out(divisor_normalized), .offset(divisor_offset)
    );
endmodule

module normalizer4significands_inputs(
    input start, clk,
    input [26:0]  man_in,
    output reg ready,
    output reg [26:0] man_out,
    reg [4:0] offset
    );
    reg iteration_flag;
    always_ff @(posedge(clk))
        if(start)
            if(~ready)
                if(iteration_flag)
                    if(man_out[26]) {offset, man_out, iteration_flag, ready} = {offset, man_out, 2'b11};
                    else            {offset, man_out, iteration_flag, ready} = {offset+5'b1, man_out<<1, 2'b10};
                else if(man_in==0)  {offset, man_out, ready} = 33'b1;
                else if(man_in[26]) {offset, man_out, iteration_flag, ready} = {5'b0, man_in,  2'b01};
                else                {offset, man_out, iteration_flag, ready} = {5'b0, man_in<<1,  2'b10};
            else {offset, man_out, iteration_flag, ready} = {offset, man_out,  2'b01};
        else {man_out, iteration_flag, ready} = 29'b0;
endmodule
/*-----------------  DIVISOR END  -------------------*/

/*------------------- SQRT BEGIN --------------------*/
module SQRT(
    input start, rst, clk,
    input [7:0] exp_in,
    input [27:0] man_in,
    output ready,
    output [7:0] exp_out,
    output [27:0] man_out
    );
    wire man_ready;
    wire [4:0] desp2rigth_from_sqrt, desp2rigth_from_mul, man_offset;
    wire [26:0] man_normalized;
    wire [27:0] man_from_sqrt, man_from_mul;
    // exp_in[0] = 1 -> (exp_in-127) is even
    assign exp_out = (exp_in[0] | (man_offset[0] & exp_in==8'b0)) ? (( ((unsigned'(exp_in)-unsigned'({3'b0, man_offset})-unsigned'(127)) >> 1)+unsigned'(127) )+unsigned'({3'b0, desp2rigth_from_sqrt})) :
                                 (( ((unsigned'(exp_in)-unsigned'({3'b0, man_offset})-unsigned'(128)) >> 1)+unsigned'(127) )+unsigned'({3'b0, desp2rigth_from_mul })) ;
    assign man_out = (exp_in[0] | (man_offset[0] & exp_in==8'b0)) ? man_from_sqrt : man_from_mul;
    significand_sqrt significand_sqrt_unit(
        .start(man_ready), .rst(rst), .clk(clk), .frac_in(man_normalized[25:3]),
        .ready(ready), .desp2rigth_out(desp2rigth_from_sqrt), .man_output(man_from_sqrt)
    );
    significands_multiplier significands_multiplier_unit(
        .man_in_1(man_from_sqrt), .man_in_2(28'b01_01101010000010011110011_000), .previus_desp2rigth(desp2rigth_from_sqrt),
        .man_output(man_from_mul), .actual_desp2rigth(desp2rigth_from_mul)
    );
    normalizer4significands_inputs normalizer4significands_inputs_sqrt_unit(
        .start(start), .clk(clk), .man_in(man_in[26:0]),
        .ready(man_ready), .man_out(man_normalized), .offset(man_offset)
    );
endmodule

module significand_sqrt( // = sqrt({1,frac_in})
    input start, rst, clk,
    input [22:0] frac_in,
    output reg ready,
    output [4:0] desp2rigth_out,
    output [27:0] man_output // bit_1, bit_0, bitexp_out_-1, ..., bit_-23, bit_g, bit_r, bit_s
    );
    typedef enum {
        waiting_state, iteration_1, iteration_2, iteration_3, iteration_4, final_state
    } state_type;
    state_type actual_state, next_state;
    reg set, sel;
    wire [4:0] desp2rigth_to_reg, 
               desp2rigth_from_reg,
               desp2rigth_to_multiplier_1,
               desp2rigth_from_multiplier_1_to_multiplier_2,
               desp2rigth_from_multiplier_2_to_multiplier_3;
    wire [22:0] magic_number_to_sub_1;
    wire [27:0] temp_to_reg,
                temp_from_reg,
                to_multiplier_1_and_3,
                from_mul_2_to_sub_2,
                from_sub_2_to_mul_3,
                from_mul_1_to_mul_2,
                res_from_sub_1;
    // MUX
    assign {to_multiplier_1_and_3, desp2rigth_to_multiplier_1} = sel ? {temp_from_reg, desp2rigth_from_reg} : {res_from_sub_1, 5'b0} ;
    // lookup table
    assign magic_number_to_sub_1 = ( (frac_in >= 23'b00000000000000000000000) & (frac_in <= 23'b00111111111111111111111) ) ? 23'b10000001100001001111010 :
                                   ( (frac_in >= 23'b01000000000000000000000) & (frac_in <= 23'b01011111111111111111111) ) ? 23'b10000100110111010000111 :
                                   ( (frac_in >= 23'b01100000000000000000000) & (frac_in <= 23'b01111111111111111111111) ) ? 23'b10001010111111001100111 :
                                   ( (frac_in >= 23'b10000000000000000000000) & (frac_in <= 23'b10011111111111111111111) ) ? 23'b10010001011001000011000 :
                                   ( (frac_in >= 23'b10100000000000000000000) & (frac_in <= 23'b10111111111111111111111) ) ? 23'b10011001000100100100010 :
                                   ( (frac_in >= 23'b11000000000000000000000) & (frac_in <= 23'b11011111111111111111111) ) ? 23'b10100010100010100001111 :
                                   ( (frac_in >= 23'b11100000000000000000000) & (frac_in <= 23'b11111111111111111111111) ) ? 23'b10110101011111011100101 : 23'bX;
    // FSM
    always_ff @(posedge(clk)) actual_state <= rst ? waiting_state : next_state;
    always_comb begin
        case(actual_state)
            default: begin
                {sel, set, ready} = 3'b000;
                next_state = actual_state;
            end
            waiting_state: begin
                {sel, set, ready} = 3'b000;
                next_state = start ? iteration_1 : waiting_state;
            end
            iteration_1: begin
                {sel, set, ready} = 3'b010;
                next_state = iteration_2;
            end
            iteration_2: begin
                {sel, set, ready} = 3'b110;
                next_state = iteration_3;
            end
            iteration_3: begin
                {sel, set, ready} = 3'b110;
                next_state = iteration_4;
            end
            iteration_4: begin
                {sel, set, ready} = 3'b110;
                next_state = final_state;        
            end
            final_state: begin
                {sel, set, ready} = 3'b001;
                next_state = start ? final_state : waiting_state;        
            end
        endcase
    end
    // sub: |man_in_1 - man_in_2|
    significands_subtractor sub_1(
        .man_in_1({3'b1, frac_in, 2'b00}), .man_in_2({2'b01, magic_number_to_sub_1, 3'b0}),
        .man_output(res_from_sub_1)
    );
    significands_subtractor sub_2(
        .man_in_1({3'b011, 25'b0}), .man_in_2(from_mul_2_to_sub_2),
        .man_output(from_sub_2_to_mul_3)
    );
    // mul: man_in_1 * man_in_2
    significands_multiplier mul_1(
        .man_in_1(to_multiplier_1_and_3), .man_in_2(to_multiplier_1_and_3), .previus_desp2rigth(desp2rigth_to_multiplier_1),
        .man_output(from_mul_1_to_mul_2), .actual_desp2rigth(desp2rigth_from_multiplier_1_to_multiplier_2)
    );
    significands_multiplier mul_2(
        .man_in_1(from_mul_1_to_mul_2), .man_in_2({3'b1, frac_in, 2'b00}), .previus_desp2rigth(desp2rigth_from_multiplier_1_to_multiplier_2),
        .man_output(from_mul_2_to_sub_2), .actual_desp2rigth(desp2rigth_from_multiplier_2_to_multiplier_3)
    );
    significands_multiplier mul_3(
        .man_in_1(to_multiplier_1_and_3), .man_in_2(from_sub_2_to_mul_3), .previus_desp2rigth(desp2rigth_from_multiplier_2_to_multiplier_3),
        .man_output(temp_to_reg), .actual_desp2rigth(desp2rigth_to_reg)
    );
    significands_multiplier mul_4(
        .man_in_1(temp_from_reg), .man_in_2({2'b1, frac_in, 3'b00}), .previus_desp2rigth(desp2rigth_from_reg),
        .man_output(man_output), .actual_desp2rigth(desp2rigth_out)
    );
    // register
    generic_register #(.width(33)) temp_register(
        .clk(clk), .reset(1'b0), .load(set), .data_in({temp_to_reg, desp2rigth_to_reg}),
        .data_out({temp_from_reg, desp2rigth_from_reg})
    );
endmodule

module significands_subtractor( // |man_in_1 - man_in_2|
    input [27:0] man_in_1, man_in_2,
    output [27:0] man_output
    );
    wire sticky;
    wire [27:0] temp;
    assign temp = ( unsigned'(man_in_1) >= unsigned'(man_in_2) ) ?
                  ( unsigned'(man_in_1)  - unsigned'(man_in_2) ) :
                  ( unsigned'(man_in_2)  - unsigned'(man_in_1) ) ;
    assign sticky = (man_in_1[0] | man_in_2[0] | temp[0]) ? 1 : 0;
    assign man_output = {temp[27:1], sticky};
endmodule
/*--------------------  SQRT END  -------------------*/
/**********  Arithmetic Units: end  ******************/

/***  Exceptions and trivial cases checker: begin  ***/
module excep_triv_checker(
        input start, clk,
        input [2:0] rm,
        input [1:0] op,
        input sig1, sig2,
        input [7:0] exp1, exp2,
        input [23:0] frac1, frac2,
        output ready,
        output reg [2:0] status_out, sel_out
        /* 
            rm =
                000 -> RNE
                001 -> RTZ
                010 -> RDN
                011 -> RUP
                100 -> RMM
            op =
                00 -> ADD
                01 -> MUL
                10 -> DIV
                11 -> SQRT
            ---------------------------------------
            status_out =
                000 -> no flag
                101 -> no flag (not used)
                110 -> no flag (not used)
                --------------
                001 -> UF flag
                010 -> OF flag
                011 -> NV flag
                100 -> DZ flag
                111 -> NX flag (not used here)
            sel_out =
                000 -> no trivial
                001 -> in1
                010 -> in2
                011 -> almost inf
                100 -> zero
                101 -> almost zero
                110 -> inf
                111 -> nan
        */
    );
    wire in1_is_nan, in2_is_nan, in1_is_zero, in2_is_zero, in1_is_inf, in2_is_inf, sig1_equal_sig2, xor_sigs, ready1, ready2;
    wire[26:0] man1_normalized, man2_normalized;
    wire [9:0] mul_exp_initial_res, div_exp_initial_res;
    wire [4:0] offset1, offset2;
    assign ready = ((ready1 | in1_is_zero) & (ready2 | in2_is_zero)) ? 1'b1 : 1'b0;
    assign in1_is_nan = (exp1 == 8'b11111111 & frac1[22:0] != 23'b0) ? 1 : 0;
    assign in2_is_nan = (exp2 == 8'b11111111 & frac2[22:0] != 23'b0) ? 1 : 0;
    assign in1_is_zero = (exp1 == 8'b0 & frac1[22:0] == 23'b0) ? 1 : 0;
    assign in2_is_zero = (exp2 == 8'b0 & frac2[22:0] == 23'b0) ? 1 : 0;
    assign in1_is_inf = (exp1 == 8'b11111111 & frac1[22:0] == 23'b0) ? 1 : 0;
    assign in2_is_inf = (exp2 == 8'b11111111 & frac2[22:0] == 23'b0) ? 1 : 0;
    assign sig1_equal_sig2 = (sig1 == sig2) ? 1 : 0;
    assign xor_sigs = (sig1^sig2) ? 1 : 0;
    assign mul_exp_initial_res = signed'({2'b0, exp1}) - signed'({5'b0, offset1}) + signed'({2'b0, exp2}) - signed'({5'b0, offset2}) - signed'(10'b001111111);
    assign div_exp_initial_res = signed'({2'b0, exp1}) - signed'({5'b0, offset1}) - signed'({2'b0, exp2}) + signed'({5'b0, offset2}) + signed'(10'b001111111);
    always_comb
        if(in1_is_nan | (in2_is_nan & (op != 2'b11))) {status_out, sel_out} = {3'b011, 3'b111}; // NV flag - nan
        else case (op)
            2'b00: // ADD
                casex ({in1_is_zero, in2_is_zero, in1_is_inf, in2_is_inf})
                    4'b1X_0X: {status_out, sel_out} = {3'b000, 3'b010}; // no flag - in2
                    4'b01_X0: {status_out, sel_out} = {3'b000, 3'b001}; // no flag - in1
                    4'b00_11: {status_out, sel_out} = xor_sigs ? {3'b011, 3'b111} : // NV flag - nan
                                                                 {3'b000, 3'b001} ; // no flag - in1
                    4'b00_10: {status_out, sel_out} = {3'b000, 3'b001}; // no flag - in1
                    4'b00_01: {status_out, sel_out} = {3'b000, 3'b010}; // no flag - in2
                    default:  {status_out, sel_out} = {3'b000, 3'b000}; // no flag - no trivial
                endcase
            2'b01: // MUL
                casex ({in1_is_zero, in2_is_zero, in1_is_inf, in2_is_inf})
                    4'b1X_01: {status_out, sel_out} = {3'b011, 3'b111}; // NV flag - nan
                    4'b1X_00: {status_out, sel_out} = {3'b000, 3'b100}; // no flag - zero
                    4'b01_10: {status_out, sel_out} = {3'b011, 3'b111}; // NV flag - nan
                    4'b01_00: {status_out, sel_out} = {3'b000, 3'b100}; // no flag - zero
                    4'b00_1X: {status_out, sel_out} = {3'b000, 3'b110}; // no flag - inf
                    4'b00_X1: {status_out, sel_out} = {3'b000, 3'b110}; // no flag - inf
                    default:
                        if(signed'(mul_exp_initial_res)>=signed'(10'b0011111111)) begin
                            // OF flag - "inf" or "almost inf" (for DIV or MUL)
                            status_out = 3'b010;
                            sel_out = (rm == 3'b001) ? 3'b011 :                        // RTZ
                                     ((rm == 3'b010) ? ( xor_sigs ? 3'b110 : 3'b011) : // RDN
                                     ((rm == 3'b011) ? (~xor_sigs ? 3'b110 : 3'b011) : // RUP
                                     3'b110));                                         // RNE - RMM
                        end
                        else if(signed'(mul_exp_initial_res)<signed'(-24)) begin
                            // Uf flag - "zero" or "almost zero" (for DIV or MUL)
                            status_out = 3'b001;
                            sel_out = (rm == 3'b001) ? 3'b100 :                        // RTZ
                                     ((rm == 3'b010) ? ( xor_sigs ? 3'b101 : 3'b100) : // RDN
                                     ((rm == 3'b011) ? (~xor_sigs ? 3'b101 : 3'b100) : // RUP
                                     3'b100));                                         // RNE - RMM
                        end
                        else {status_out, sel_out} = {3'b000, 3'b000}; // no flag - no trivial
                endcase
            2'b10: // DIV
                casex ({in1_is_zero, in2_is_zero, in1_is_inf, in2_is_inf})
                    4'b11_00: {status_out, sel_out} = {3'b011, 3'b111}; // NV flag - nan
                    4'b10_0X: {status_out, sel_out} = {3'b000, 3'b100}; // no flag - zero
                    4'b01_X0: {status_out, sel_out} = {3'b100, 3'b110}; // DZ flag - inf
                    4'b00_11: {status_out, sel_out} = {3'b011, 3'b111}; // NV flag - nan
                    4'b00_10: {status_out, sel_out} = {3'b000, 3'b110}; // no flag - inf
                    4'b00_01: {status_out, sel_out} = {3'b000, 3'b100}; // no flag - zero
                    default:
                        if(signed'(div_exp_initial_res)>=signed'(10'b0011111111)) begin
                            if((unsigned'(man1_normalized)<unsigned'(man2_normalized))&(signed'(div_exp_initial_res)==signed'(10'b0011111111)))
                                {status_out, sel_out} = {3'b000, 3'b000}; // no flag - 
                            else begin 
                                // OF flag - "inf" or "almost inf" (for DIV or MUL)
                                status_out = 3'b010;
                                sel_out = (rm == 3'b001) ? 3'b011 :                        // RTZ
                                         ((rm == 3'b010) ? ( xor_sigs ? 3'b110 : 3'b011) : // RDN
                                         ((rm == 3'b011) ? (~xor_sigs ? 3'b110 : 3'b011) : // RUP
                                         3'b110));   
                            end
                                                                  // RNE - RMM
                        end
                        else if(signed'(div_exp_initial_res)<signed'(-24)) begin
                            // Uf flag - "zero" or "almost zero" (for DIV or MUL)
                            status_out = 3'b001;
                            sel_out = (rm == 3'b001) ? 3'b100 :                        // RTZ
                                     ((rm == 3'b010) ? ( xor_sigs ? 3'b101 : 3'b100) : // RDN
                                     ((rm == 3'b011) ? (~xor_sigs ? 3'b101 : 3'b100) : // RUP
                                     3'b100));                                         // RNE - RMM
                        end
                        else {status_out, sel_out} = {3'b000, 3'b000}; // no flag - no trivial  
                endcase
            default: // SQRT
                if(sig1) {status_out, sel_out} = {3'b011, 3'b111}; // NV flag - nan
                else if(in1_is_zero | in1_is_inf) {status_out, sel_out} = {3'b000, 3'b001}; // no flag - in1
                else {status_out, sel_out} = {3'b000, 3'b000}; // no flag - no trivial
        endcase
    normalizer4significands_inputs normalizer4significands_inputs_checker1(
        .start(start), .clk(clk), .man_in({frac1[23:0], 3'b0}),
        .ready(ready1), .man_out(man1_normalized), .offset(offset1)
    );
    normalizer4significands_inputs normalizer4significands_inputs_checker2(
        .start(start), .clk(clk), .man_in({frac2[23:0], 3'b0}),
        .ready(ready2), .man_out(man2_normalized), .offset(offset2)
    );
endmodule
/***  Exceptions and trivial cases checker: end  *****/