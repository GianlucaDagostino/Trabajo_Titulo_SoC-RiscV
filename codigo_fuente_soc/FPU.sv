/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021
*/
`timescale 1ns / 1ps

module fpu_op_selection(
    input [4:0] rs2_add,
    input [3:0] funct7_out,
    input [2:0] format_type, sub_format_type, funct3, rm_from_fcsr,
    output reg [2:0] rm2fpu,
    output reg [4:0] fpu_option
    );
    assign rm2fpu = (funct3 == 3'b111) ? rm_from_fcsr : funct3;
    always_comb begin
        if(format_type[2:1]==2'b00)
            if(format_type[0]) // R4
                case (sub_format_type)
                    3'b000:     fpu_option = 5'b0_00_00; // fmadd.s
                    3'b001:     fpu_option = 5'b0_00_01; // fmsub.s
                    3'b010:     fpu_option = 5'b0_00_10; // fnmsub.s
                    3'b011:     fpu_option = 5'b0_00_11; // fnmadd.s
                    default: fpu_option = 5'b1_11_11;    // not valid option
                endcase
            else // R
                if(sub_format_type!=3'b000) fpu_option = 5'b1_11_11; // not valid option
                else 
                    case(funct7_out)
                        /*---------------------------------------------------------------*/
                        4'b0000: fpu_option = 5'b 1_00_00; // fadd.s
                        4'b0011: fpu_option = 5'b 1_00_01; // fsub.s
                        4'b0100: fpu_option = 5'b 1_00_10; // fmul.s
                        4'b0101: fpu_option = 5'b 1_00_11; // fdiv.s
                        4'b0110: fpu_option = 5'b 1_01_00; // fsqrt.s
                        /*---------------------------------------------------------------*/
                        4'b0111:case(funct3)
                                    3'b000:  fpu_option = 5'b0_11_00; // fsgnj.s
                                    3'b001:  fpu_option = 5'b0_11_01; // fsgnjn.s
                                    3'b010:  fpu_option = 5'b0_11_10; // fsgnjx.s
                                    default: fpu_option = 5'b1_11_11; // not valid option
                                endcase
                        /*---------------------------------------------------------------*/
                        4'b1000:case(funct3)
                                    3'b000:  fpu_option = 5'b0_10_00; // fmin.s
                                    3'b001:  fpu_option = 5'b0_10_01; // fmax.s
                                    default: fpu_option = 5'b1_11_11; // not valid option
                                endcase
                        /*---------------------------------------------------------------*/
                        4'b1001:case(rs2_add)
                                    5'b00000: fpu_option = 5'b0_01_00; // fcvt.s.w
                                    5'b00001: fpu_option = 5'b0_01_01; // fcvt.s.wu
                                    default:  fpu_option = 5'b1_11_11; // not valid option
                                endcase
                        4'b1010:case(rs2_add)
                                    5'b00000: fpu_option = 5'b0_01_10; // fcvt.w.s
                                    5'b00001: fpu_option = 5'b0_01_11; // fcvt.wu.s
                                    default:  fpu_option = 5'b1_11_11; // not valid option
                                endcase
                        /*---------------------------------------------------------------*/
                        4'b 1101:case(funct3)
                                    3'b000:  fpu_option = 5'b1_10_00; // fle.s
                                    3'b001:  fpu_option = 5'b1_10_01; // flt.s
                                    3'b010:  fpu_option = 5'b1_10_10; // feq.s
                                    default: fpu_option = 5'b1_11_11; // not valid option
                                endcase
                        /*---------------------------------------------------------------*/
                        4'b1011: fpu_option = (funct3==3'b001) ? 5'b0_11_11 : 5'b1_11_11; // fclass.s
                        /*---------------------------------------------------------------*/
                        default: fpu_option = 5'b1_11_11; // not valid option
                    endcase
        else fpu_option = 5'b1_11_11; // not valid option
    end
endmodule
/*
option = f(format_type[2:0], funct7_out[3:0], funct3[2:0], rs2_option)
    format_type[2:0]= (only for FPU)
        000 -> R type
        001 -> R4 type
        011 -> S type (mem option, not used here)
        010 -> I type (mem option, not used here)
        111 -> Not valid type
    sub_format_type[2:0]= (only for R4)
        -000 -> R4 (FP- fmadd.s)
        -001 -> R4 (FP- fmsub.s)
        -010 -> R4 (FP- fnmsub.s)
        -011 -> R4 (FP- fnmadd.s)
    funct7_out[3:0]= (only for FPU)
        if  Funct7[6:0]=0000000: Funct7-out[3:0]=0000
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
    funct3[2:0]= 000 | 001 | 010 | rm
    rm[2:0]=
        000 -> RNE
        001 -> RTZ
        010 -> RDN
        011 -> RUP
        100 -> RMM
        101 -> (Invalid)
        110 -> (Invalid)
        111 -> DYN: In instruction's rm field, selects dynamic rounding mode; In Rounding Mode register, Invalid.
    rs2_option= 0 | 1
    
    =           format_type  sub_format_type  funct3  funct7_out  rs2_add ->  fpu_option
        --------------------------------------------------------------------------------
        fmadd.s     R4 001        000           rm      ----      -----   ->    0_00_00
        fmsub.s     R4 001        001           rm      ----      -----   ->    0_00_01     DA: double arithmetic
        fnmsub.s    R4 001        010           rm      ----      -----   ->    0_00_10     0_00_XX
        fnmadd.s    R4 001        011           rm      ----      -----   ->    0_00_11
        --------------------------------------------------------------------------------
        fadd.s      R  000        000           rm      0000      -----   ->    1_00_00
        fsub.s      R  000        000           rm      0011      -----   ->    1_00_01
        fmul.s      R  000        000           rm      0100      -----   ->    1_00_10     AM: arithmetic
        fdiv.s      R  000        000           rm      0101      -----   ->    1_00_11     1_0X_XX
        fsqrt.s     R  000        000           rm      0110      00000   ->    1_01_00
        --------------------------------------------------------------------------------
        fsgnj.s     R  000        000           000     0111      -----   ->    0_11_00
        fsgnjn.s    R  000        000           001     0111      -----   ->    0_11_01     SG: sgnj
        fsgnjx.s    R  000        000           010     0111      -----   ->    0_11_10     0_11_XX
        --------------------------------------------------------------------------------
        fmin.s      R  000        000           000     1000      -----   ->    0_10_00     MM: max/min
        fmax.s      R  000        000           001     1000      -----   ->    0_10_01     0_10_0X
        --------------------------------------------------------------------------------
        fcvt.s.w    R  000        000           rm      1001      00000   ->    0_01_00
        fcvt.s.wu   R  000        000           rm      1001      00001   ->    0_01_01     CO: Convertions
        fcvt.w.s    R  000        000           rm      1010      00000   ->    0_01_10     0_01_XX
        fcvt.wu.s   R  000        000           rm      1010      00001   ->    0_01_11 
        --------------------------------------------------------------------------------
        fle.s       R  000        000           000     1101      -----   ->    1_10_00
        flt.s       R  000        000           001     1101      -----   ->    1_10_01     CM: Comparisson 
        feq.s       R  000        000           010     1101      -----   ->    1_10_10     1_10_XX
        --------------------------------------------------------------------------------
        fclass.s    R  000        000           001     1011      00000   ->    0_11_11     CS: Class
        --------------------------------------------------------------------------------    0_11_11
                                                                                1_11_11 not valid
*/
module FPU(
    input start, rst, clk, // start: Need to be on til the op is ready
    input [2:0] rm,
    input [4:0] option,
    input [31:0] in1, in2, in3,
    output reg NV, NX, UF, OF, DZ, ready,
    output reg [31:0] out
    );
    typedef enum {
        waiting_state, CS_state, MM_state, CM_state, CO_state, SG_state,
        DA_state1, DA_state2, DA_state3, DA_state4, AM_state
    } state_type;
    state_type actual_state, next_state;
    reg sel_arithmetic, start_to_arithmetic, rst_to_arithmetic, set_reg_arithmetic;
    reg [2:0] op_to_arithmetic;
    wire NX_from_converter, NV_from_converter, NV_from_comparator,
        ready_from_arithmetic, ready_from_converter, NV_max_min, in1_is_nan, in2_is_nan,
        UF_from_arithmetic, OF_from_arithmetic, NV_from_arithmetic, DZ_from_arithmetic, NX_from_arithmetic,
        NV_r4_middle, NX_r4_middle, UF_r4_middle, OF_r4_middle, DZ_r4_middle;
    wire [2:0] status_from_arithmetic;
    wire [31:0] in1_to_fp_arithmetic_unit, in2_to_fp_arithmetic_unit, r4_middle_out,
        out_from_arithmetic, out_from_converter, out_from_classifier, out_from_comparator,
        sgnj_out, max_min_out;
    assign in1_is_nan = (in1[30:23] == 8'b11111111 & in1[22:0] != 23'b0) ? 1 : 0;
    assign in2_is_nan = (in2[30:23] == 8'b11111111 & in2[22:0] != 23'b0) ? 1 : 0;
    // SG: sgnj
    assign sgnj_out = {(option[0] ? ~in2[31] : (option[1] ? in1[31]^in2[31] : in2[31])), in1[30:0]};
    // MM: max/min /* notese que los inputs op del modulo fp_comparator para ambos casos (max min) es considerado */
    /*
        option[1:0]=01 > flt y max | option[1:0]=00 > fle y min

        option[0]=1 -> lt: in1 <  in2 (flag signaling: signaling comparison) flag when Nan in (res = 0)
        option[0]=0 -> le: in1 <= in2 (flag signaling: signaling comparison) flag when Nan in (res = 0) 
    */
    assign max_min_out = ~(in1_is_nan & in2_is_nan) ? (option[0] ?
            (out_from_comparator[0] ? (in2_is_nan ? in1 : in2) : (in1_is_nan ? in2 : in1)) : // max-flt
            (out_from_comparator[0] ? (in1_is_nan ? in2 : in1) : (in2_is_nan ? in1 : in2))   // min-fle
        ) : 32'b0_11111111_10000000000000000000000;
    assign NV_max_min  = ((in1_is_nan&~in1[22]) | (in2_is_nan&~in2[22])) ? 1'b1 : 1'b0;
    // DA: double arithmetic
    assign in1_to_fp_arithmetic_unit = sel_arithmetic ? r4_middle_out : in1;
    assign in2_to_fp_arithmetic_unit = sel_arithmetic ? in3           : in2;
    assign UF_from_arithmetic = (status_from_arithmetic==3'b001) ? 1'b1 : 1'b0;
    assign OF_from_arithmetic = (status_from_arithmetic==3'b010) ? 1'b1 : 1'b0;
    assign NV_from_arithmetic = (status_from_arithmetic==3'b011) ? 1'b1 : 1'b0;
    assign DZ_from_arithmetic = (status_from_arithmetic==3'b100) ? 1'b1 : 1'b0;
    assign NX_from_arithmetic = (status_from_arithmetic==3'b111 | 
                                 status_from_arithmetic==3'b001) ? 1'b1 : 1'b0;
    /*
        status =
            001 -> UF flag
            010 -> OF flag
            011 -> NV flag
            100 -> DZ flag
            111 -> NX flag
    */
    // FSM
    always_ff @(posedge(clk)) actual_state <= rst ? waiting_state : next_state;
    always_comb
        case (actual_state)
            default: begin
                out = 32'b0;
                {NV, NX, UF, OF, DZ, ready} = 6'b00000_0;
                {sel_arithmetic, start_to_arithmetic, rst_to_arithmetic, set_reg_arithmetic, op_to_arithmetic} = {4'b0000, 3'b000};
                next_state = actual_state;
            end
            waiting_state: begin
                out = 32'b0;
                {NV, NX, UF, OF, DZ, ready} = 6'b00000_0;
                {sel_arithmetic, start_to_arithmetic, rst_to_arithmetic, set_reg_arithmetic, op_to_arithmetic} = {4'b0010, 3'b000};
                next_state = start ? ((option[4:0]==5'b0_11_11) ? CS_state :
                                     ((option[4:1]==4'b0_10_0 ) ? MM_state :
                                     ((option[4:2]==3'b1_10   ) ? CM_state :
                                     ((option[4:2]==3'b0_01   ) ? CO_state :
                                     ((option[4:2]==3'b0_11   ) ? SG_state :
                                     ((option[4:2]==3'b0_00   ) ? DA_state1 :
                                     ((option[4:3]==2'b1_0    ) ? AM_state :
                                     waiting_state))))))) : waiting_state;
            end
            CS_state: begin
                out = out_from_classifier;
                {NV, NX, UF, OF, DZ, ready} = 6'b00000_1;
                {sel_arithmetic, start_to_arithmetic, rst_to_arithmetic, set_reg_arithmetic, op_to_arithmetic} = {4'b0000, 3'b000};
                next_state = start ? CS_state : waiting_state;
            end
            MM_state: begin
                out = max_min_out;
                {NV, NX, UF, OF, DZ, ready} = {NV_max_min, 5'b0000_1};
                {sel_arithmetic, start_to_arithmetic, rst_to_arithmetic, set_reg_arithmetic, op_to_arithmetic} = {4'b0000, 3'b000};
                next_state = start ? MM_state : waiting_state;
            end
            CM_state: begin
                out = out_from_comparator;
                {NV, NX, UF, OF, DZ, ready} = {NV_from_comparator, 5'b0000_1};
                {sel_arithmetic, start_to_arithmetic, rst_to_arithmetic, set_reg_arithmetic, op_to_arithmetic} = {4'b0000, 3'b000};
                next_state = start ? CM_state : waiting_state;
            end
            CO_state: begin
                out = out_from_converter;
                {NV, NX, UF, OF, DZ, ready} = {NV_from_converter, NX_from_converter, 3'b000, ready_from_converter};
                {sel_arithmetic, start_to_arithmetic, rst_to_arithmetic, set_reg_arithmetic, op_to_arithmetic} = {4'b0000, 3'b000};
                next_state = start ? CO_state : waiting_state;
            end
            SG_state: begin
                out = sgnj_out;
                {NV, NX, UF, OF, DZ, ready} = 6'b00000_1;
                {sel_arithmetic, start_to_arithmetic, rst_to_arithmetic, set_reg_arithmetic, op_to_arithmetic} = {4'b0000, 3'b000};
                next_state = start ? SG_state : waiting_state;
            end
            /*
                op =
                    000 -> in1+in2   ADD    -1_0 0_00
                    001 -> in1*in2   MUL    -1_0 0_10
                    010 -> in1/in2   DIV    -1_0 0_11
                    011 -> sqrt(in1) SQRT   -1_0 1_00
                    100 -> in1-in2   SUB    -1_0 0_01
            */
            AM_state: begin
                out = out_from_arithmetic;
                {NV, NX, UF, OF, DZ, ready} = {NV_from_arithmetic, NX_from_arithmetic, UF_from_arithmetic,
                                            OF_from_arithmetic, DZ_from_arithmetic, ready_from_arithmetic};
                op_to_arithmetic = (option[2:0]==3'b0_00) ? 3'b000 : 
                                  ((option[2:0]==3'b0_01) ? 3'b100 : 
                                  ((option[2:0]==3'b0_10) ? 3'b001 : 
                                  ((option[2:0]==3'b0_11) ? 3'b010 : 
                                  ((option[2:0]==3'b1_00) ? 3'b011 : 
                                    3'bXXX))));
                {sel_arithmetic, start_to_arithmetic, rst_to_arithmetic, set_reg_arithmetic} = 4'b0100;
                next_state = start ? AM_state : waiting_state;
            end
            /*
                    fmadd.s  -> option[1:0]=00 -> rd = rs1 * rs2 + rs3
                    fmsub.s  -> option[1:0]=01 -> rd = rs1 * rs2 - rs3
                    fnmsub.s -> option[1:0]=10 -> rd = -rs1 * rs2 + rs3
                    fnmadd.s -> option[1:0]=11 -> rd = -rs1 * rs2 - rs3
                op =
                    000 -> in1+in2   ADD
                    001 -> in1*in2   MUL
                    100 -> in1-in2   SUB
                    101 -> -in1*in2  -MUL
            */
            DA_state1: begin
                out = 32'b0;
                {NV, NX, UF, OF, DZ, ready} = {NV_from_arithmetic, NX_from_arithmetic, UF_from_arithmetic,
                                            OF_from_arithmetic, DZ_from_arithmetic, 1'b0};
                op_to_arithmetic = option[1] ? 3'b101 : 3'b001;
                {sel_arithmetic, start_to_arithmetic, rst_to_arithmetic, set_reg_arithmetic} = 4'b0100;
                next_state = ready_from_arithmetic ? DA_state2 : DA_state1;
            end
            DA_state2: begin
                out = 32'b0;
                {NV, NX, UF, OF, DZ, ready} = {NV_from_arithmetic, NX_from_arithmetic, UF_from_arithmetic,
                                            OF_from_arithmetic, DZ_from_arithmetic, 1'b0};
                op_to_arithmetic = option[1] ? 3'b101 : 3'b001;
                {sel_arithmetic, start_to_arithmetic, rst_to_arithmetic, set_reg_arithmetic} = 4'b0101;
                next_state = DA_state3;
            end
            DA_state3: begin
                out = 32'b0;
                {NV, NX, UF, OF, DZ, ready} = 6'b00000_0;
                op_to_arithmetic = option[0] ? 3'b100 : 3'b000;
                {sel_arithmetic, start_to_arithmetic, rst_to_arithmetic, set_reg_arithmetic} = 4'b1010;
                next_state = DA_state4;
            end
            DA_state4: begin
                out = out_from_arithmetic;
                {NV, NX, UF, OF, DZ, ready} = {NV_from_arithmetic | NV_r4_middle, NX_from_arithmetic | NX_r4_middle,
                                               UF_from_arithmetic | UF_r4_middle, OF_from_arithmetic | OF_r4_middle,
                                               DZ_from_arithmetic | DZ_r4_middle, ready_from_arithmetic};
                op_to_arithmetic = option[0] ? 3'b100 : 3'b000;
                {sel_arithmetic, start_to_arithmetic, rst_to_arithmetic, set_reg_arithmetic} = 4'b1100;
                next_state = start ? DA_state4 : waiting_state;
            end
        endcase
    // AM: arithmetic
    fp_arithmetic_unit fp_arithmetic_unit_module(
        //inputs
        .start(start_to_arithmetic), .rst(rst | rst_to_arithmetic), .clk(clk),
        .op(op_to_arithmetic), .rm(rm),
        .in1(in1_to_fp_arithmetic_unit), .in2(in2_to_fp_arithmetic_unit),
        //outputs
        .ready(ready_from_arithmetic), .status(status_from_arithmetic), .out(out_from_arithmetic)
    );
    generic_register #(.width(32+5)) fp_arithmetic_unit_register(
        .clk(clk), .reset(1'b0), .load(set_reg_arithmetic), .data_in({NV, NX, UF, OF, DZ, out_from_arithmetic}),
        .data_out({NV_r4_middle, NX_r4_middle, UF_r4_middle, OF_r4_middle, DZ_r4_middle, r4_middle_out})
    );
    // CO: Convertions
    fp_converter fp_converter_unit(
        //inputs
        .start(start), .rst(rst), .clk(clk),
        .integer_is_signed(~option[0]), .option(option[1]), .rm(rm), .in(in1),
        /* option: 0 -> Integer to fp | 1 -> fp to Integer */
        //outputs
        .NV(NV_from_converter), .NX(NX_from_converter), .ready(ready_from_converter), .out(out_from_converter)
    );
    // CS: Class
    fp_classifier fp_classifier_unit(
        //inputs
        .in(in1),
        //outputs
        .out(out_from_classifier)
    );
    // CM: Comparisson
    fp_comparator fp_comparator_unit(
        //inputs
        .in1_is_nan(in1_is_nan), .in2_is_nan(in2_is_nan),
        .op((option[0] ? 2'b01 : (option[1] ? 2'b00 : 2'b10))), .in1(in1), .in2(in2),
        /* op
            00 -> eq: in1 == in2 (no flag signaling: quiet comparison) no flag when Nan in (res = 0)
            01 -> lt: in1 <  in2 (flag signaling: signaling comparison) flag when Nan in (res = 0)
            10 -> le: in1 <= in2 (flag signaling: signaling comparison) flag when Nan in (res = 0)
            11 -> not used but = eq
        */
        //outputs
        .invalid_flag(NV_from_comparator), .out(out_from_comparator)
    );
endmodule

module fp_classifier(
    input [31:0] in,
    output reg [31:0] out
    );
    always_comb begin
        out = 32'b0000_0000_0000_0000_0000_0000_0000_0000;        
        case (in[30:23])
            default:                if(in[31]) out[1] =1'b1; else out[6] =1'b1;
            8'b00000000:
                if(in[22:0]==23'b0) if(in[31]) out[3] =1'b1; else out[4] =1'b1;
                else                if(in[31]) out[2] =1'b1; else out[5] =1'b1;
            8'b11111111:
                if(in[22:0]==23'b0) if(in[31]) out[0] =1'b1; else out[7] =1'b1;
                else                if(in[22]) out[9] =1'b1; else out[8] =1'b1;
        endcase
    end
endmodule

module fp_comparator(
    input in1_is_nan, in2_is_nan,
    input [1:0] op, 
    input [31:0] in1, in2,
    output invalid_flag,
    output [31:0] out
    /*
    op = 
        00 -> eq: in1 == in2 (no flag signaling: quiet comparison) no flag when Nan in (res = 0)
        01 -> lt: in1 <  in2 (flag signaling: signaling comparison) flag when Nan in (res = 0)
        10 -> le: in1 <= in2 (flag signaling: signaling comparison) flag when Nan in (res = 0)
        11 -> not used but = eq
    */
    );
    reg less_flag;
    wire equal_flag;
    assign equal_flag = (in1 == in2) ? 1'b1 : 1'b0;
    assign invalid_flag = (op[1] ^ op[0]) ? (in1_is_nan | in2_is_nan) : (in1_is_nan&~in1[22] | in2_is_nan&~in2[22]);
    assign out = (op == 2'b01) ? ( (less_flag & ~(in1_is_nan | in2_is_nan))                ? 32'b1 : 32'b0 ) :
                 (op == 2'b10) ? ( ((less_flag | equal_flag) & ~(in1_is_nan | in2_is_nan)) ? 32'b1 : 32'b0 ) :
                                 ( (equal_flag & ~(in1_is_nan | in2_is_nan))               ? 32'b1 : 32'b0 ) ;
    always_comb
        if(in1[31] == in2[31]) // sig1 = sig2
            if     (unsigned'(in1[30:23]) < unsigned'(in2[30:23])) less_flag = in1[31] ? 1'b0 : 1'b1;
            else if(unsigned'(in1[30:23]) > unsigned'(in2[30:23])) less_flag = in1[31] ? 1'b1 : 1'b0;
            else // exp1 = exp2
                if     (unsigned'(in1[22:0]) < unsigned'(in2[22:0])) less_flag = in1[31] ? 1'b0 : 1'b1;
                else if(unsigned'(in1[22:0]) > unsigned'(in2[22:0])) less_flag = in1[31] ? 1'b1 : 1'b0;
                else less_flag = 1'b0; // in1 = in2
        else // sig1 != sig2
            less_flag = in1[31];
endmodule
