/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021
Test Bench for "tb_ALU.sv"
*/
`timescale 1ns / 1ps

module tb_ALU;
    reg [31:0] input_1 = 0; reg [31:0] input_2 = 0; reg [4:0] operation = 0;
    wire boolean; wire [31:0] out;
    ALU ALU_uut(
        .in1(input_1), .in2(input_2), .operation(operation),
        .res(out), .boolean_res(boolean)
    );
    initial begin
        int out_errors = 0; int boolean_errors = 0;
        reg [31:0] correct_out; reg correct_boolean;
        #10 $display("BEGIN");

        /*------- BEGIN: SET TEST 2 -------*/
        $display(">>>Test 2 - op: + add <<<");
        operation       = 5'b00_000;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b10000110001111001010101010010111;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: - sub <<<");
        operation       = 5'b00_001;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b10010101100100110010010110011111;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: ^ xor <<<");
        operation       = 5'b00_010;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b01110101101100110010101001100111;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: | or <<<");
        operation       = 5'b00_011;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b11111101111101111110101001111111;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: & and <<<");
        operation       = 5'b00_100;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b10001000010001001100000000011000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: << shift left <<<");
        operation       = 5'b00_101;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b10110000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: >> shift rigth <<<");
        operation       = 5'b00_110;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b00000000000000000000000000001000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: >> shift rigth (MSB extend) <<<");
        operation       = 5'b00_111;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b11111111111111111111111111111000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: == equality <<<");
        operation       = 5'b01_000;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: == equality <<<");
        operation       = 5'b01_000;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b10001101111001111110100000011011;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: == equality <<<");
        operation       = 5'b01_000;
        input_1         = 32'b11111000010101001100001001111100;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: != difference <<<");
        operation       = 5'b01_001;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: != difference <<<");
        operation       = 5'b01_001;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b10001101111001111110100000011011;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: != difference <<<");
        operation       = 5'b01_001;
        input_1         = 32'b11111000010101001100001001111100;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: < is less than <<<");
        operation       = 5'b01_010;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: < is less than <<<");
        operation       = 5'b01_010;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b10001101111001111110100000011011;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: < is less than <<<");
        operation       = 5'b01_010;
        input_1         = 32'b11111000010101001100001001111100;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: < is less than (unsigned) <<<");
        operation       = 5'b01_011;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: < is less than (unsigned) <<<");
        operation       = 5'b01_011;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b10001101111001111110100000011011;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: < is less than (unsigned) <<<");
        operation       = 5'b01_011;
        input_1         = 32'b11111000010101001100001001111100;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: >= is bigger or equal <<<");
        operation       = 5'b01_100;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: >= is bigger or equal <<<");
        operation       = 5'b01_100;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b10001101111001111110100000011011;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: >= is bigger or equal <<<");
        operation       = 5'b01_100;
        input_1         = 32'b11111000010101001100001001111100;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: >= is bigger or equal (unsigned) <<<");
        operation       = 5'b01_101;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: >= is bigger or equal (unsigned) <<<");
        operation       = 5'b01_101;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b10001101111001111110100000011011;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: >= is bigger or equal (unsigned) <<<");
        operation       = 5'b01_101;
        input_1         = 32'b11111000010101001100001001111100;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: * mul <<<");
        operation       = 5'b10_000;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b11001011000101001110001100010100;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: * mul high <<<");
        operation       = 5'b11_000;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b00000011011010101111101000101001;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: * mul high (unsigned) <<<");
        operation       = 5'b11_001;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b10001001101001111010010011000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: * mul high (signed*unsigned) <<<");
        operation       = 5'b11_010;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b10010001010100101110001001000100;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: / div <<<");
        operation       = 5'b10_011;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b00000000000000000000000000001110;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: / div (unsigned) <<<");
        operation       = 5'b10_100;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: % modulo <<<");
        operation       = 5'b10_101;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b11111001010001010100010101010011;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 2 - op: % modulo (unsigned) <<<");
        operation       = 5'b10_111;
        input_1         = 32'b10001101111001111110100000011011;
        input_2         = 32'b11111000010101001100001001111100;
        correct_out     = 32'b10001101111001111110100000011011;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        /*-------- END:  SET TEST 2 -------*/

        /*------- BEGIN: SET TEST 3 -------*/
        $display(">>>Test 3 - op: + add <<<");
        operation       = 5'b00_000;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b11111101111101111111100110101001;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: - sub <<<");
        operation       = 5'b00_001;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00110111100110110100010010111101;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: ^ xor <<<");
        operation       = 5'b00_010;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b11111001111001111100010101000101;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: | or <<<");
        operation       = 5'b00_011;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b11111011111011111101111101110111;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: & and <<<");
        operation       = 5'b00_100;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00000010000010000001101000110010;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: << shift left <<<");
        operation       = 5'b00_101;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b11001100110000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: >> shift rigth <<<");
        operation       = 5'b00_110;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00000000000000000000001001101011;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: >> shift rigth (MSB extend) <<<");
        operation       = 5'b00_111;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b11111111111111111111111001101011;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: == equality <<<");
        operation       = 5'b01_000;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: == equality <<<");
        operation       = 5'b01_000;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b10011010110010011001111100110011;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: == equality <<<");
        operation       = 5'b01_000;
        input_1         = 32'b01100011001011100101101001110110;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: != difference <<<");
        operation       = 5'b01_001;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: != difference <<<");
        operation       = 5'b01_001;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b10011010110010011001111100110011;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: != difference <<<");
        operation       = 5'b01_001;
        input_1         = 32'b01100011001011100101101001110110;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: < is less than <<<");
        operation       = 5'b01_010;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: < is less than <<<");
        operation       = 5'b01_010;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b10011010110010011001111100110011;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: < is less than <<<");
        operation       = 5'b01_010;
        input_1         = 32'b01100011001011100101101001110110;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: < is less than (unsigned) <<<");
        operation       = 5'b01_011;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: < is less than (unsigned) <<<");
        operation       = 5'b01_011;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b10011010110010011001111100110011;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: < is less than (unsigned) <<<");
        operation       = 5'b01_011;
        input_1         = 32'b01100011001011100101101001110110;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: >= is bigger or equal <<<");
        operation       = 5'b01_100;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00000000000000000000000000000000;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: >= is bigger or equal <<<");
        operation       = 5'b01_100;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b10011010110010011001111100110011;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: >= is bigger or equal <<<");
        operation       = 5'b01_100;
        input_1         = 32'b01100011001011100101101001110110;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: >= is bigger or equal (unsigned) <<<");
        operation       = 5'b01_101;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: >= is bigger or equal (unsigned) <<<");
        operation       = 5'b01_101;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b10011010110010011001111100110011;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: >= is bigger or equal (unsigned) <<<");
        operation       = 5'b01_101;
        input_1         = 32'b01100011001011100101101001110110;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b1;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: * mul <<<");
        operation       = 5'b10_000;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b10001111000100010100111110000010;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: * mul high <<<");
        operation       = 5'b11_000;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b11011000110010011010010100000111;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: * mul high (unsigned) <<<");
        operation       = 5'b11_001;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00111011111101111111111101111101;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: * mul high (signed*unsigned) <<<");
        operation       = 5'b11_010;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b11011000110010011010010100000111;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: / div <<<");
        operation       = 5'b10_011;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b11111111111111111111111111111111;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: / div (unsigned) <<<");
        operation       = 5'b10_100;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00000000000000000000000000000001;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: % modulo <<<");
        operation       = 5'b10_101;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b11111101111101111111100110101001;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        $display(">>>Test 3 - op: % modulo (unsigned) <<<");
        operation       = 5'b10_111;
        input_1         = 32'b10011010110010011001111100110011;
        input_2         = 32'b01100011001011100101101001110110;
        correct_out     = 32'b00110111100110110100010010111101;
        correct_boolean = 1'b0;
        #10;
        $display("Inputs");
        $display("operation: %b", operation);
        $display("in1      : %b", input_1);
        $display("in2      : %b", input_2);
        $display("Outputs");
        if(out == correct_out) $display("res: PASSED!!");
        else begin
            out_errors += 1;
            $display("res: FAILED!!");
            $display("res should be: %b", correct_out);
        end
        $display("res          : %b", out);
        if(boolean == correct_boolean) $display("boolean_res: PASSED!!");
        else begin
            boolean_errors += 1;
            $display("boolean_res: FAILED!!");
            $display("boolean_res should be: %b", correct_boolean);
        end
        $display("boolean_res          : %b", boolean);
        #10;
        $display("-------------------");
        /*-------- END:  SET TEST 3 -------*/

        $display("Total errors found            : %d (%f percentage)", out_errors+boolean_errors, (out_errors+boolean_errors)*100.0/136);
        $display("Total out errors found        : %d (%f percentage)", out_errors, out_errors*100.0/68);
        $display("Total boolean errors found    : %d (%f percentage)", boolean_errors, boolean_errors*100.0/68);
        $display("END"); #10 $finish;
    end
endmodule