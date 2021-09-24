/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021
*/
`timescale 1ns / 1ps

module tb_FPU;
    // FPU inputs
    reg start = 0; reg rst = 0; reg clk = 0;
    reg [2:0] rm_to_FPU = 0; reg [4:0] option_to_FPU = 0;
    reg [31:0] input_1 = 0; reg [31:0] input_2 = 0; reg [31:0] input_3 = 0;
    // fpu_op_selection inputs
    reg [4:0] rs2_add = 0; reg [3:0] funct7_out = 0;
    reg [2:0] format_type = 0; reg [2:0] sub_format_type = 0;
    reg [2:0] funct3 = 0; reg [2:0] rm_from_fcsr = 0;
    // FPU outputs
    wire ready, NV, NX, UF, OF, DZ;
    wire [31:0] out;
    // fpu_op_selection outputs
    wire [2:0] rm_fpu_op_selection;
    wire [4:0] option_fpu_op_selection;

    FPU FPU_uut(
        // Inputs
        .start(start), .rst(rst), .clk(clk), // start: Need to be on til the op is ready
        .rm(rm_to_FPU), .option(option_to_FPU), .in1(input_1), .in2(input_2), .in3(input_3),
        // Outputs
        .ready(ready), .NV(NV), .NX(NX), .UF(UF), .OF(OF), .DZ(DZ), .out(out)
    );
    fpu_op_selection fpu_op_selection_uut(
        // Inputs
        .rs2_add(rs2_add), .funct7_out(funct7_out), 
        .format_type(format_type), .sub_format_type(sub_format_type),
        .funct3(funct3), .rm_from_fcsr(rm_from_fcsr),
        // Outputs
        .rm2fpu(rm_fpu_op_selection), .fpu_option(option_fpu_op_selection)
    );

    always #5 clk = ~clk;

    initial begin
        #10 start = 0;
        // FPU
        option_to_FPU = 5'b0_01_00;
        rm_to_FPU = 3'b000;
        input_1 = 32'b1111_1111_1111_1111_1111_1111_1111_1010;
        input_2 = 32'b1111111111100;
        input_3 = 32'b0;
        // fpu_op_selection
        rs2_add         = 5'b00000;
        funct7_out      = 4'b0110;
        format_type     = 3'b000;
        sub_format_type = 3'b000;
        funct3          = 3'b111;
        rm_from_fcsr    = 3'b011;
        ////////////////////////////////////////////////////////////////////////
        #10 start = 1;
        while(~ready) #10;
        // FPU
        $display("FPU- out: %b", out);
        $display("FPU- NV, NX, UF, OF, DZ: %b \n", {NV, NX, UF, OF, DZ});
        // fpu_op_selection
        $display("fpu_op_selection- rm2fpu: %b", rm_fpu_op_selection);
        $display("fpu_op_selection- fpu_option: %b \n", option_fpu_op_selection);
        #10 start = 0; #10 $finish;
    end
endmodule
