/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021

gcc tb_ALU_gen.c -o tb_ALU_gen
./tb_ALU_gen

    0  operation=00_000: + add
    1  operation=00_001: - sub
    2  operation=00_010: ^ xor
    3  operation=00_011: | or
    4  operation=00_100: & and
    5  operation=00_101: << shift left
    6  operation=00_110: >> shift rigth
    7  operation=00_111: >> shift rigth (MSB extend)

    8  operation=01_000: == equality
    9  operation=01_001: != difference
    10 operation=01_010: < is less than
    11 operation=01_011: < is less than (unsigned)
    12 operation=01_100: >= is bigger or equal
    13 operation=01_101: >= is bigger or equal (unsigned)

    14 operation=10_000: * mul
    15 operation=10_001: * mul (unsigned)
    16 operation=10_010: / div
    17 operation=10_011: / div (unsigned)
    18 operation=10_100: % modulo
    19 operation=10_101: % modulo (unsigned)
*/
#include "./common_functions.h"
void fput_test_ALU(FILE* file, char test_number[5], int option, char in1[37], char in2[37], char out[37], int boolean_out){
    fputs("        $display(\">>>Test ", file); fputs(test_number, file); fputs(" - op: ", file);
    if(option==0)       fputs("+ add <<<\");\n        operation       = 5'b00_000", file);
    else if(option== 1) fputs("- sub <<<\");\n        operation       = 5'b00_001", file);
    else if(option== 2) fputs("^ xor <<<\");\n        operation       = 5'b00_010", file);
    else if(option== 3) fputs("| or <<<\");\n        operation       = 5'b00_011", file);
    else if(option== 4) fputs("& and <<<\");\n        operation       = 5'b00_100", file);
    else if(option== 5) fputs("<< shift left <<<\");\n        operation       = 5'b00_101", file);
    else if(option== 6) fputs(">> shift rigth <<<\");\n        operation       = 5'b00_110", file);
    else if(option== 7) fputs(">> shift rigth (MSB extend) <<<\");\n        operation       = 5'b00_111", file);
    else if(option== 8) fputs("== equality <<<\");\n        operation       = 5'b01_000", file);
    else if(option== 9) fputs("!= difference <<<\");\n        operation       = 5'b01_001", file);
    else if(option==10) fputs("< is less than <<<\");\n        operation       = 5'b01_010", file);
    else if(option==11) fputs("< is less than (unsigned) <<<\");\n        operation       = 5'b01_011", file);
    else if(option==12) fputs(">= is bigger or equal <<<\");\n        operation       = 5'b01_100", file);
    else if(option==13) fputs(">= is bigger or equal (unsigned) <<<\");\n        operation       = 5'b01_101", file);
    else if(option==14) fputs("* mul <<<\");\n        operation       = 5'b10_000", file);
    else if(option==15) fputs("* mul high <<<\");\n        operation       = 5'b11_000", file);
    else if(option==16) fputs("* mul high (unsigned) <<<\");\n        operation       = 5'b11_001", file);
    else if(option==17) fputs("* mul high (signed*unsigned) <<<\");\n        operation       = 5'b11_010", file);
    else if(option==18) fputs("/ div <<<\");\n        operation       = 5'b10_011", file);
    else if(option==19) fputs("/ div (unsigned) <<<\");\n        operation       = 5'b10_100", file);
    else if(option==20) fputs("\% modulo <<<\");\n        operation       = 5'b10_101", file);
    else if(option==21) fputs("\% modulo (unsigned) <<<\");\n        operation       = 5'b10_111", file);
    fputs(";\n        input_1         = ", file); fputs(in1, file);
    fputs(";\n        input_2         = ", file); fputs(in2, file);
    fputs(";\n        correct_out     = ", file); fputs(out, file);
    fputs(";\n        correct_boolean = 1'b", file); if(boolean_out) fputs("1;\n", file); else fputs("0;\n", file);
    fputs("        #10;\n        $display(\"Inputs\");\n        $display(\"operation: \%b\", operation);\n        $display(\"in1      : \%b\", input_1);\n        $display(\"in2      : \%b\", input_2);\n        $display(\"Outputs\");\n", file);
    fputs("        if(out == correct_out) $display(\"res: PASSED!!\");\n        else begin\n            out_errors += 1;\n            $display(\"res: FAILED!!\");\n            $display(\"res should be: \%b\", correct_out);\n        end\n        $display(\"res          : \%b\", out);\n", file);
    fputs("        if(boolean == correct_boolean) $display(\"boolean_res: PASSED!!\");\n        else begin\n            boolean_errors += 1;\n            $display(\"boolean_res: FAILED!!\");\n            $display(\"boolean_res should be: \%b\", correct_boolean);\n        end\n        $display(\"boolean_res          : \%b\", boolean);\n", file);
    fputs("        #10;\n        $display(\"-------------------\");\n", file);
}
int main(){
    FILE* file;
    char percentage_info[5];
    char str_num_tests[7]; // max input = 99999
    int num_tests, num_tests_discarded;
    int is_big_endian = is_big_endian_test();
    file  = fopen ("tb_ALU.sv", "w");
    fputs("/*\nautor: Gianluca Vincenzo D'Agostino Matute\nSantiago de Chile, Septiembre 2021\nTest Bench for \"tb_ALU.sv\"\n*/\n`timescale 1ns / 1ps\n\nmodule tb_ALU;\n", file);
    fputs("    reg [31:0] input_1 = 0; reg [31:0] input_2 = 0; reg [4:0] operation = 0;\n    wire boolean; wire [31:0] out;\n", file);
    fputs("    ALU ALU_uut(\n        .in1(input_1), .in2(input_2), .operation(operation),\n        .res(out), .boolean_res(boolean)\n    );\n", file);
    fputs("    initial begin\n        int out_errors = 0; int boolean_errors = 0;\n        reg [31:0] correct_out; reg correct_boolean;\n        #10 $display(\"BEGIN\");\n\n", file);
    printf("Enter n° of set test to write (max input 99999): ");
    fgets(str_num_tests, sizeof(str_num_tests), stdin);
    num_tests = atoi(str_num_tests);
    memset(str_num_tests,0,sizeof(str_num_tests));
    printf("Enter n° of initial set test to discard (max input 99999): ");
    fgets(str_num_tests, sizeof(str_num_tests), stdin);
    num_tests_discarded = atoi(str_num_tests);
    memset(str_num_tests,0,sizeof(str_num_tests));
    for(int i = 0 ; i < num_tests ; i++){
        int in1, in2, out;
        unsigned int in1_unsig, in2_unsig;
        long long_out;
        unsigned long long_out_unsig;
        unsigned char *rand_byte_0, *rand_byte_1, *rand_byte_2, *rand_byte_3, *target_add;
        char out_str[37];
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
            if(k) {in1 = *( (unsigned int*) target_add ); in1_unsig = *( (unsigned int*) target_add );}
            else  {in2 = *( (unsigned int*) target_add ); in2_unsig = *( (unsigned int*) target_add );}
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
            // Se realizan los tests
        
            // 0  operation=00_000: + add
            out = (unsigned int) ( ( (unsigned int) in1 ) + ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 0, in1_str, in2_str, out_str, 0);  // Se imprime test

            // 1  operation=00_001: - sub
            out = (unsigned int) ( ( (unsigned int) in1 ) - ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 1, in1_str, in2_str, out_str, 0);  // Se imprime test

            // 2  operation=00_010: ^ xor
            out = (unsigned int) ( ( (unsigned int) in1 ) ^ ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 2, in1_str, in2_str, out_str, 0);  // Se imprime test

            // 3  operation=00_011: | or
            out = (unsigned int) ( ( (unsigned int) in1 ) | ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 3, in1_str, in2_str, out_str, 0);  // Se imprime test

            // 4  operation=00_100: & and
            out = (unsigned int) ( ( (unsigned int) in1 ) & ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 4, in1_str, in2_str, out_str, 0);  // Se imprime test

            // 5  operation=00_101: << shift left
            out = (unsigned int) ( ( (unsigned int) in1 ) << ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 5, in1_str, in2_str, out_str, 0);  // Se imprime test

            // 6  operation=00_110: >> shift rigth
            out = (unsigned int) ( ( (unsigned int) in1 ) >> ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 6, in1_str, in2_str, out_str, 0);  // Se imprime test

            // 7  operation=00_111: >> shift rigth (MSB extend)
            out = (unsigned int) ( ( (int) in1 ) >> ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 7, in1_str, in2_str, out_str, 0);  // Se imprime test

            // 8a  operation=01_000: == equality
            out = (unsigned int) ( ( (unsigned int) in1 ) == ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 8, in1_str, in2_str, out_str, out);  // Se imprime test
            // 8b  operation=01_000: == equality
            out = (unsigned int) ( ( (unsigned int) in1 ) == ( (unsigned int) in1 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 8, in1_str, in1_str, out_str, out);  // Se imprime test
            // 8c  operation=01_000: == equality
            out = (unsigned int) ( ( (unsigned int) in2 ) == ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 8, in2_str, in2_str, out_str, out);  // Se imprime test

            // 9a  operation=01_001: != difference
            out = (unsigned int) ( ( (unsigned int) in1 ) != ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 9, in1_str, in2_str, out_str, out);  // Se imprime test
            // 9b  operation=01_001: != difference
            out = (unsigned int) ( ( (unsigned int) in1 ) != ( (unsigned int) in1 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 9, in1_str, in1_str, out_str, out);  // Se imprime test
            // 9c  operation=01_001: != difference
            out = (unsigned int) ( ( (unsigned int) in2 ) != ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 9, in2_str, in2_str, out_str, out);  // Se imprime test

            // 10a operation=01_010: < is less than
            out = (unsigned int) ( ( (int) in1 ) < ( (int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 10, in1_str, in2_str, out_str, out);  // Se imprime test
            // 10b operation=01_010: < is less than
            out = (unsigned int) ( ( (int) in1 ) < ( (int) in1 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 10, in1_str, in1_str, out_str, out);  // Se imprime test
            // 10c operation=01_010: < is less than
            out = (unsigned int) ( ( (int) in2 ) < ( (int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 10, in2_str, in2_str, out_str, out);  // Se imprime test

            // 11a operation=01_011: < is less than (unsigned)
            out = (unsigned int) ( ( (unsigned int) in1 ) < ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 11, in1_str, in2_str, out_str, out);  // Se imprime test
            // 11b operation=01_011: < is less than (unsigned)
            out = (unsigned int) ( ( (unsigned int) in1 ) < ( (unsigned int) in1 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 11, in1_str, in1_str, out_str, out);  // Se imprime test
            // 11c operation=01_011: < is less than (unsigned)
            out = (unsigned int) ( ( (unsigned int) in2 ) < ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 11, in2_str, in2_str, out_str, out);  // Se imprime test

            // 12a operation=01_100: >= is bigger or equal
            out = (unsigned int) ( ( (int) in1 ) >= ( (int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 12, in1_str, in2_str, out_str, out);  // Se imprime test
            // 12b operation=01_100: >= is bigger or equal
            out = (unsigned int) ( ( (int) in1 ) >= ( (int) in1 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 12, in1_str, in1_str, out_str, out);  // Se imprime test
            // 12c operation=01_100: >= is bigger or equal
            out = (unsigned int) ( ( (int) in2 ) >= ( (int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 12, in2_str, in2_str, out_str, out);  // Se imprime test

            // 13a operation=01_101: >= is bigger or equal (unsigned)
            out = (unsigned int) ( ( (unsigned int) in1 ) >= ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 13, in1_str, in2_str, out_str, out);  // Se imprime test
            // 13b operation=01_101: >= is bigger or equal (unsigned)
            out = (unsigned int) ( ( (unsigned int) in1 ) >= ( (unsigned int) in1 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 13, in1_str, in1_str, out_str, out);  // Se imprime test
            // 13c operation=01_101: >= is bigger or equal (unsigned)
            out = (unsigned int) ( ( (unsigned int) in2 ) >= ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 13, in2_str, in2_str, out_str, out);  // Se imprime test
            
            // 14 operation=10_000: * mul
            out = (unsigned int) ( ( (int) in1 ) * ( (int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 14, in1_str, in2_str, out_str, 0);  // Se imprime test
            
            // 15 operation=11_000: * mul high
            long_out = (long) ((long) in1)*((long) in2);
            long_out = long_out >> 32;
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &long_out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 15, in1_str, in2_str, out_str, 0);  // Se imprime test
            
            // 16 operation=11_001: * mul high (unsigned)
            long_out_unsig = (unsigned long) ((unsigned long) in1_unsig)*((unsigned long) in2_unsig);
            long_out_unsig = long_out_unsig >> 32;
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &long_out_unsig); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 16, in1_str, in2_str, out_str, 0);  // Se imprime test
            
            // 17 operation=11_010: * mul high (signed*unsigned)
            long_out = (long) ((long) in1)*((unsigned long) in2_unsig);
            long_out = long_out >> 32;
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &long_out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 17, in1_str, in2_str, out_str, 0);  // Se imprime test

            // 18 operation=10_011: / div
            out = (unsigned int) ( ( (int) in1 ) / ( (int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 18, in1_str, in2_str, out_str, 0);  // Se imprime test

            // 19 operation=10_100: / div (unsigned)
            out = (unsigned int) ( ( (unsigned int) in1 ) / ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 19, in1_str, in2_str, out_str, 0);  // Se imprime test

            // 20 operation=10_101: % modulo
            out = (unsigned int) ( ( (int) in1 ) % ( (int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 20, in1_str, in2_str, out_str, 0);  // Se imprime test

            // 21 operation=10_111: % modulo (unsigned)
            out = (unsigned int) ( ( (unsigned int) in1 ) % ( (unsigned int) in2 ) );
            memset(out_str,0,sizeof(out_str));
            get_binary(out_str, &out); // Se obtiene la representación binaria del resultado
            fput_test_ALU(file, current_test_str, 21, in1_str, in2_str, out_str, 0);  // Se imprime test
            
            // Titulo de cierre del set de pruebas
            fputs(test_title___end, file);
        }

    }
    fputs("        $display(\"Total errors found            : \%d (\%f percentage)\", out_errors+boolean_errors, (out_errors+boolean_errors)*100.0/", file);
    sprintf(percentage_info, "%d", (num_tests-num_tests_discarded)*(22+12)*2); fputs(percentage_info, file); memset(percentage_info,0,sizeof(percentage_info)); sprintf(percentage_info, "%d", (num_tests-num_tests_discarded)*(22+12));
    fputs(");\n        $display(\"Total out errors found        : \%d (\%f percentage)\", out_errors, out_errors*100.0/", file); fputs(percentage_info, file);
    fputs(");\n        $display(\"Total boolean errors found    : \%d (\%f percentage)\", boolean_errors, boolean_errors*100.0/", file); fputs(percentage_info, file);
    fputs(");\n        $display(\"END\"); #10 $finish;\n    end\nendmodule", file);
    fclose(file);
    printf("N° of tests written: %d\nOperation ready, file generated: tb_fp_arithmetic_unit.sv\n", (num_tests-num_tests_discarded)*(22+12));
    return 0;
}