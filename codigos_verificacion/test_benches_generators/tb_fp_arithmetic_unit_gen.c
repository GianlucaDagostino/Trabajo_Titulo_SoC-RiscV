/*  
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021

gcc tb_fp_arithmetic_unit_gen.c -o tb_fp_arithmetic_unit_gen -lm
./tb_fp_arithmetic_unit_gen

op =
    000 -> in1+in2   ADD                        code= 0
    001 -> in1*in2   MUL                        code= 1
    010 -> in1/in2   DIV                        code= 2
    011 -> sqrt(in1) SQRT (not exactly equal)   code= 3
    100 -> in1-in2   SUB                        code= 4
    101 -> -in1*in2  -MUL (not tested)
    110 -> -in1/in2  -DIV (not tested)
rm =
    000 -> RNE  code= 0
    001 -> RTZ  code= 1
    010 -> RDN  code= 2
    011 -> RUP  code= 3
    100 -> RMM  code= 4 (not tested)
status =
    000 -> no flag (used)       code= 0
    101 -> no flag (not used)
    110 -> no flag (not used)
    --------------
    001 -> UF flag              code= 1
    010 -> OF flag              code= 2
    011 -> NV flag              code= 3
    100 -> DZ flag              code= 4
    111 -> NX flag              code= 5

https://www.h-schmidt.net/FloatConverter/IEEE754.html
*/

#include "./common_functions.h"

int exceptions_checker(void){
    if(fetestexcept(FE_DIVBYZERO)) return 4;
    else if(fetestexcept(FE_INVALID)) return 3;
    else if(fetestexcept(FE_OVERFLOW)) return 2;
    else if(fetestexcept(FE_UNDERFLOW)) return 1;
    else if(fetestexcept(FE_INEXACT)) return 5;
    else return 0;
}

void fput_test_fp_arithmetic_unit(FILE* file, char test_number[5], int op, int rm,
                            char in1[37], char in2[37], char out[37], int status){
    fputs("        $display(\">>>Test ", file); fputs(test_number, file);
    if(op==0) fputs("-ADD", file); else if(op==1) fputs("-MUL", file); else if(op==2) fputs("-DIV", file); else if(op==3) fputs("-SQRT", file); else if(op==4) fputs("-SUB", file);
    if(rm==0) fputs("-RNE", file); else if(rm==1) fputs("-RTZ", file); else if(rm==2) fputs("-RDN", file); else if(rm==3) fputs("-RUP", file); else if(rm==4) fputs("-RMM", file);
    fputs(" <<<\");\n        operation     = 3'b", file);
    if(op==0) fputs("000;\n", file); else if(op==1) fputs("001;\n", file); else if(op==2) fputs("010;\n", file); else if(op==3) fputs("011;\n", file); else if(op==4) fputs("100;\n", file);
    fputs("        rounding_mode = 3'b", file);
    if(rm==0) fputs("000;\n", file); else if(rm==1) fputs("001;\n", file); else if(rm==2) fputs("010;\n", file); else if(rm==3) fputs("011;\n", file); else if(rm==4) fputs("100;\n", file);
    fputs("        input_1 = ", file); fputs(in1, file); fputs(";\n        input_2 = ", file); fputs(in2, file); fputs(";\n        correct_out = ", file); fputs(out, file);
    fputs(";\n        correct_status = 3'b", file);
    if(status==0) fputs("000;\n", file); else if(status==1) fputs("001;\n", file); else if(status==2) fputs("010;\n", file); else if(status==3) fputs("011;\n", file); else if(status==4) fputs("100;\n", file); else if(status==5) fputs("111;\n", file);
    fputs("        $display(\"In1: \%b\", input_1);\n        $display(\"In2: \%b\", input_2);\n        $display(\"Operation: \%b\", operation);\n        $display(\"Rounding_Mode: \%b\", rounding_mode);\n", file);
    fputs("        #200 start = 1;\n        initial_time = $time;\n        while(~ready) #10;\n        elapsed_time = $time-initial_time;\n        $display(\"Initial time: \%t\", initial_time);\n        $display(\"Elapsed time: \%t\", elapsed_time);\n", file);
    
    if(op==2 | op==3) fputs("        if(out == correct_out | out == {correct_out[31:23], correct_out[22:0]+23'b1} | out == {correct_out[31:23], correct_out[22:0]-23'b1} | out == {correct_out[31:23], correct_out[22:0]+23'b10} | out == {correct_out[31:23], correct_out[22:0]-23'b10} | out[30:0]==31'b1111111110000000000000000000000) $display(\"out: PASSED!!\");\n", file);
    else fputs("        if(out == correct_out | out[30:0]==31'b1111111110000000000000000000000) $display(\"out: PASSED!!\");\n", file);

    fputs("        else begin\n            man_out_errors += 1;\n            $display(\"out: FAILED!!\");\n            $display(\"out should be: \%b\", correct_out);\n        end\n        $display(\"out          : \%b\", out);\n", file);
    fputs("        if(status == correct_status) $display(\"status: PASSED!!\");\n        else begin\n            status_out_errors += 1;\n            $display(\"status: FAILED!!\");\n            $display(\"status should be: \%b\", correct_status);\n        end\n        $display(\"status: \%b\", status);\n", file);
    fputs("        if(elapsed_time > max_elapsed_time) max_elapsed_time = elapsed_time;\n        if(elapsed_time < min_elapsed_time) min_elapsed_time = elapsed_time;\n        #200 start = 0;\n        $display(\"-------------\");\n", file);
}

int main(){
    FILE* file;
    char percentage_info[4];
    char str_num_tests[7]; // max input = 99999
    int num_tests, num_tests_discarded;
    int original_rounding = fegetround();
    int is_big_endian = is_big_endian_test();
    file  = fopen ("tb_fp_arithmetic_unit.sv", "w");
    fputs("/*\nautor: Gianluca Vincenzo D'Agostino Matute\nSantiago de Chile, Septiembre 2021\nTest Bench for \"tb_fp_arithmetic_unit.sv\"\n*/\n`timescale 1ns / 1ps\n\nmodule tb_fp_arithmetic_unit;\n", file);
    fputs("    //global inputs\n    reg start = 0; reg rst = 0; reg clk = 0;\n", file);
    fputs("    reg [31:0] input_1 = 0; reg [31:0] input_2 = 0;\n    reg [2:0] operation = 0; reg [2:0] rounding_mode = 0;\n", file);
    fputs("    //global outputs\n    wire ready; wire [2:0] status; wire [31:0] out;\n\n", file);
    fputs("    // uut\n    fp_arithmetic_unit uut_fp_arithmetic_unit(\n", file);
    fputs("        //input\n        .start(start), .rst(rst), .clk(clk),\n        .op(operation), .rm(rounding_mode),\n", file);
    fputs("        .in1(input_1), .in2(input_2),\n        //output\n        .ready(ready), .status(status), .out(out)\n    );\n\n", file);
    fputs("    always #5 clk = ~clk;\n\n    initial begin\n        int man_out_errors = 0; int status_out_errors = 0;\n", file);
    fputs("        int min_elapsed_time = 100000; int max_elapsed_time = 0;\n        int initial_time, elapsed_time;\n\n", file);
    fputs("        reg [31:0] correct_out; reg [2:0] correct_status;\n\n        $display(\"BEGIN\"); start = 0;\n\n", file);
    printf("Enter n° of set test to write (max input 99999): ");
    fgets(str_num_tests, sizeof(str_num_tests), stdin);
    num_tests = atoi(str_num_tests);
    memset(str_num_tests,0,sizeof(str_num_tests));
    printf("Enter n° of initial set test to discard (max input 99999): ");
    fgets(str_num_tests, sizeof(str_num_tests), stdin);
    num_tests_discarded = atoi(str_num_tests);
    memset(str_num_tests,0,sizeof(str_num_tests));
    for(int i = 0 ; i < num_tests ; i++){
        float in1, in2;
        unsigned char *rand_byte_0, *rand_byte_1, *rand_byte_2, *rand_byte_3, *target_add;
        char in1_str[37] = "";
        char in2_str[37] = "";
        char current_test_str[5] = "";
        char test_title_begin[50] = "        /*------- BEGIN: SET TEST ";
        char test_title___end[50] = "        /*-------- END:  SET TEST ";
        // Se asigna espacio en memoria para cada byte aleatorio
        rand_byte_0 = malloc(sizeof(unsigned char));
        rand_byte_1 = malloc(sizeof(unsigned char));
        rand_byte_2 = malloc(sizeof(unsigned char));
        rand_byte_3 = malloc(sizeof(unsigned char));
        // Se alinean los bytes
        rand_byte_1 = rand_byte_0 + 1;
        rand_byte_2 = rand_byte_1 + 1;
        rand_byte_3 = rand_byte_2 + 1;
        // Se determina dirección
        target_add = is_big_endian ? rand_byte_3 : rand_byte_0;
        // Se obtienen los bits aleatorios para cada input
        for(int k = 0 ; k < 2 ; k++){
            *rand_byte_0 = (unsigned char) rand_range(256);
            *rand_byte_1 = (unsigned char) rand_range(256);
            *rand_byte_2 = (unsigned char) rand_range(256);
            *rand_byte_3 = (unsigned char) rand_range(256);
            // Se obtienen los resultados aleatorios
            if(k) in1 = *( (float*) target_add ); else in2 = *( (float*) target_add );
        }
        if(i >= num_tests_discarded) {
            // Se escribe encabezado del test
            sprintf(current_test_str, "%d", i);
            strcat(test_title_begin, current_test_str);
            strcat(test_title___end, current_test_str);
            strcat(test_title_begin, " -------*/\n");
            strcat(test_title___end, " -------*/\n\n");
            fputs(test_title_begin, file);
            // Se obtiene el string con la representación binaria para cada input
            get_binary(in1_str, &in1);
            get_binary(in2_str, &in2);
            // Ciclo para cada modo de redondeo
            for(int j = 0 ; j < 4 ; j++){
                int op, status;
                float out;
                char out_str[37];
                if(j==0) fesetround(FE_TONEAREST); else if(j==1) fesetround(FE_TOWARDZERO);
                else if(j==2) fesetround(FE_DOWNWARD); else if(j==3) fesetround(FE_UPWARD);

                // ADD
                if(feclearexcept(FE_ALL_EXCEPT)) printf("feclearexcept(FE_ALL_EXCEPT) FAILED!!\n"); // Se limpian las excepciones
                out = (in1+in2); // Se realiza la operación por testear
                status = exceptions_checker(); // Se obtiene el status correspondiente
                memset(out_str,0,sizeof(out_str));
                if(isnanf(out)) {strcat(out_str, "32'b11111111110000000000000000000000"); status=3;}
                else get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
                fput_test_fp_arithmetic_unit(file, current_test_str, 0, j, in1_str, in2_str, out_str, status); // Se imprime test
                
                // MUL
                if(feclearexcept(FE_ALL_EXCEPT)) printf("feclearexcept(FE_ALL_EXCEPT) FAILED!!\n"); // Se limpian las excepciones
                out = (in1*in2); // Se realiza la operación por testear
                status = exceptions_checker(); // Se obtiene el status correspondiente
                memset(out_str,0,sizeof(out_str));
                if(isnanf(out)) {strcat(out_str, "32'b11111111110000000000000000000000"); status=3;}
                else get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
                fput_test_fp_arithmetic_unit(file, current_test_str, 1, j, in1_str, in2_str, out_str, status); // Se imprime test
                
                // DIV
                if(feclearexcept(FE_ALL_EXCEPT)) printf("feclearexcept(FE_ALL_EXCEPT) FAILED!!\n"); // Se limpian las excepciones
                out = (in1/in2); // Se realiza la operación por testear
                status = exceptions_checker(); // Se obtiene el status correspondiente
                memset(out_str,0,sizeof(out_str));
                if(isnanf(out)) {strcat(out_str, "32'b11111111110000000000000000000000"); status=3;}
                else get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
                fput_test_fp_arithmetic_unit(file, current_test_str, 2, j, in1_str, in2_str, out_str, status); // Se imprime test
                
                // SQRT
                if(feclearexcept(FE_ALL_EXCEPT)) printf("feclearexcept(FE_ALL_EXCEPT) FAILED!!\n"); // Se limpian las excepciones
                out = sqrt(in1); // Se realiza la operación por testear
                status = exceptions_checker(); // Se obtiene el status correspondiente
                memset(out_str,0,sizeof(out_str));
                if(isnanf(out)) {strcat(out_str, "32'b11111111110000000000000000000000"); status=3;}
                else get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
                fput_test_fp_arithmetic_unit(file, current_test_str, 3, j, in1_str, in2_str, out_str, status); // Se imprime test
                
                // SUB
                if(feclearexcept(FE_ALL_EXCEPT)) printf("feclearexcept(FE_ALL_EXCEPT) FAILED!!\n"); // Se limpian las excepciones
                out = in1 - in2; // Se realiza la operación por testear
                status = exceptions_checker(); // Se obtiene el status correspondiente
                memset(out_str,0,sizeof(out_str));
                if(isnanf(out)) {strcat(out_str, "32'b11111111110000000000000000000000"); status=3;}
                else get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
                fput_test_fp_arithmetic_unit(file, current_test_str, 4, j, in1_str, in2_str, out_str, status); // Se imprime test
            }
            // Titulo de cierre del set de pruebas
            fputs(test_title___end, file);
        }
    }
    fputs("        $display(\"Total errors found: %d (\%f percentage)\", man_out_errors+status_out_errors, (man_out_errors+status_out_errors)*100.0/", file);
    sprintf(percentage_info, "%d", (num_tests-num_tests_discarded)*4*5*2); fputs(percentage_info, file); memset(percentage_info,0,sizeof(percentage_info)); sprintf(percentage_info, "%d", (num_tests-num_tests_discarded)*4*5);
    fputs(");\n        $display(\"Total out errors found: %d (\%f percentage)\", man_out_errors, man_out_errors*100.0/", file); fputs(percentage_info, file);
    fputs(");\n        $display(\"Total status errors found: %d (\%f percentage)\", status_out_errors, status_out_errors*100.0/", file); fputs(percentage_info, file);
    fputs(");\n        $display(\"Minimum elapsed time: %d\", min_elapsed_time);\n        $display(\"Maximum elapsed time: %d\", max_elapsed_time);\n", file);
    fputs("        $display(\"END\"); #10 $finish;\n    end\nendmodule", file);
    fclose(file);
    fesetround(original_rounding);
    printf("N° of tests written: %d\nOperation ready, file generated: tb_fp_arithmetic_unit.sv\n", (num_tests-num_tests_discarded)*4*5);
    return 0;
}