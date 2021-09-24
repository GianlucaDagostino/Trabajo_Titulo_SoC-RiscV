/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021

gcc tb_fp_converter_gen.c -o tb_fp_converter_gen -lm
./tb_fp_converter_gen

option: 0 -> Integer to fp / 1 -> fp to Integer
rm =
    000 -> RNE - code = 0
    001 -> RTZ - code = 1
    010 -> RDN - code = 2
    011 -> RUP - code = 3
    100 -> RMM - code = 4 (not tested)

https://www.h-schmidt.net/FloatConverter/IEEE754.html

*/

#include "./common_functions.h"

void fput_test_fp_converter(FILE* file, char test_number[4], int option, int integer_is_signed, int rm,
                            char in[37], char out[37], int NV, int NX){
    fputs("        $display(\">>>Test ", file); fputs(test_number, file);
    if(option) if(integer_is_signed) fputs("-fp2signed", file); else fputs("-fp2unsigned", file);
    else if(integer_is_signed) fputs("-signed2fp", file); else fputs("-unsigned2fp", file);
    if(rm==0) fputs("-RNE", file); else if(rm==1) fputs("-RTZ", file); else if(rm==2) fputs("-RDN", file); else if(rm==3) fputs("-RUP", file); else if(rm==4) fputs("-RMM", file);
    fputs(" <<<\");\n        option = 1'b", file);
    if(option) fputs("1;\n", file); else fputs("0;\n", file);
    fputs("        integer_is_signed = 1'b", file);
    if(integer_is_signed) fputs("1;\n", file); else fputs("0;\n", file);
    fputs("        rm = 3'b", file);
    if(rm==0)fputs("000", file); else if(rm==1) fputs("001", file); else if(rm==2) fputs("010", file); else if(rm==3) fputs("011", file); else fputs("100", file);
    fputs(";\n        in = ", file); fputs(in, file); fputs(";\n        correct_out = ", file); fputs(out, file);
    fputs(";\n        correct_NV = 1'b", file); if(NV) fputs("1", file); else fputs("0", file);
    fputs(";\n        correct_NX = 1'b", file); if(NX) fputs("1", file); else fputs("0", file);
    fputs(";\n        $display(\"in: \%b\", in);\n        $display(\"integer_is_signed: \%b\", integer_is_signed);\n        $display(\"option: \%b\", option);\n        $display(\"rm: \%b\", rm);\n", file);
    fputs("        #10 start = 1;\n        initial_time = $time;\n        while(~ready) #10;\n        elapsed_time = $time-initial_time;\n", file);
    fputs("        $display(\"Initial time: \%t\", initial_time);\n        $display(\"Elapsed time: \%t\", elapsed_time);\n", file);
    fputs("        if(out == correct_out) $display(\"out: PASSED!!\");\n        else begin\n            out_errors += 1;\n            $display(\"out: FAILED!!\");\n", file);
    fputs("            $display(\"out should be: \%b\", correct_out);\n        end\n        $display(\"out: \%b\", out);\n", file);
    fputs("        if(NV == correct_NV) $display(\"NV: PASSED!!\");\n        else begin\n            NV_errors += 1;\n            $display(\"NV: FAILED!!\");\n", file);
    fputs("            $display(\"NV should be: \%b\", correct_NV);\n        end\n        $display(\"NV: \%b\", NV);\n", file);
    fputs("        if(NX == correct_NX) $display(\"NX: PASSED!!\");\n        else begin\n            NX_errors += 1;\n            $display(\"NX: FAILED!!\");\n", file);
    fputs("            $display(\"NX should be: \%b\", correct_NX);\n        end\n        $display(\"NX: \%b\", NX);\n", file);
    fputs("        if(elapsed_time > max_elapsed_time) max_elapsed_time = elapsed_time;\n        if(elapsed_time < min_elapsed_time) min_elapsed_time = elapsed_time;\n        #10 start = 0;\n        $display(\"-------------\");\n", file);
}

int main(){
    FILE* file;
    char percentage_info[4];
    char str_num_tests[7]; // max input = 99999
    int num_tests, num_tests_discarded;
    int original_rounding = fegetround();
    int is_big_endian = is_big_endian_test();
    file  = fopen ("tb_fp_converter.sv", "w");
    fputs("/*\nautor: Gianluca Vincenzo D'Agostino Matute\nSantiago de Chile, Septiembre 2021\nTest Bench for \"fp_converter.sv\"\n*/\n`timescale 1ns / 1ps\n\nmodule tb_fp_converter;\n", file);
    fputs("    reg start = 0; reg rst = 0; reg clk = 0;\n    reg option = 0; reg integer_is_signed = 0;\n", file);
    fputs("    reg [2:0] rm = 0; reg [31:0] in = 0;\n    // option: 0 -> Integer to fp | 1 -> fp to Integer\n", file);
    fputs("    wire NV, NX, ready; wire [31:0] out;\n    fp_converter uut(\n        .start(start), .rst(rst), .clk(clk),\n", file);
    fputs("        .integer_is_signed(integer_is_signed), .option(option), .rm(rm), .in(in),\n        .NV(NV), .NX(NX), .ready(ready), .out(out)\n", file);
    fputs("    );\n    always #5 clk = ~clk;\n    initial begin\n", file);
    fputs("        int out_errors = 0; int NV_errors = 0; int NX_errors = 0;\n        int min_elapsed_time = 100000; int max_elapsed_time = 0;\n", file);
    fputs("        int initial_time, elapsed_time;\n        reg [31:0] correct_out; reg correct_NV, correct_NX;\n        $display(\"BEGIN\"); start = 0;\n\n", file);
    printf("Enter n° of set test to write (max input 99999): ");
    fgets(str_num_tests, sizeof(str_num_tests), stdin);
    num_tests = atoi(str_num_tests);
    memset(str_num_tests,0,sizeof(str_num_tests));
    printf("Enter n° of initial set test to discard (max input 99999): ");
    fgets(str_num_tests, sizeof(str_num_tests), stdin);
    num_tests_discarded = atoi(str_num_tests);
    memset(str_num_tests,0,sizeof(str_num_tests));
    for(int i = 0 ; i < num_tests ; i++){
        int random_signed;
        unsigned int random_unsigned;
        float random_float;
        unsigned char *rand_byte_0, *rand_byte_1, *rand_byte_2, *rand_byte_3, *target_add;
        char in_str[37] = "";
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
        // Se obtienen los bits aleatorios
        *rand_byte_0 = (unsigned char) rand_range(256);
        *rand_byte_1 = (unsigned char) rand_range(256);
        *rand_byte_2 = (unsigned char) rand_range(256);
        *rand_byte_3 = (unsigned char) rand_range(256);
        if(i >= num_tests_discarded) {
            // Titulo del set de pruebas
            sprintf(current_test_str, "%d", i);
            strcat(test_title_begin, current_test_str);
            strcat(test_title___end, current_test_str);
            strcat(test_title_begin, " -------*/\n");
            strcat(test_title___end, " -------*/\n\n");
            fputs(test_title_begin, file);
            // Se determina dirección
            target_add = is_big_endian ? rand_byte_3 : rand_byte_0;
            // Se obtienen los enteros y el float aleatorios a partir de los bytes aleatorios
            random_signed   = *( (int*) target_add );
            random_unsigned = *( (unsigned int*) target_add );
            random_float    = *( (float*) target_add );
            // se obtiene representación binaria
            get_binary(in_str, target_add);
            // Ciclo para cada modo de redondeo
            for(int j = 0 ; j < 4 ; j++){
                int fp2signed;
                unsigned int fp2unsigned;
                float signed2fp, unsigned2fp;
                int NV, NX;
                char out_str[37];
                if(j==0) fesetround(FE_TONEAREST); else if(j==1) fesetround(FE_TOWARDZERO);
                else if(j==2) fesetround(FE_DOWNWARD); else if(j==3) fesetround(FE_UPWARD);

                // {option, integer_is_signed} = {0, 0}: unsigned2fp
                if(feclearexcept(FE_ALL_EXCEPT)) printf("feclearexcept(FE_ALL_EXCEPT) FAILED!!\n"); // Se limpian las excepciones
                unsigned2fp = (float) random_unsigned;
                NV = fetestexcept(FE_INVALID);
                NX = fetestexcept(FE_INEXACT);
                memset(out_str,0,sizeof(out_str));
                get_binary(out_str, &unsigned2fp); // Se obtiene la representación binaria del resultado
                fput_test_fp_converter(file, current_test_str, 0, 0, j, in_str, out_str, NV, NX);  // Se imprime test

                // {option, integer_is_signed} = {0, 1}: signed2fp
                if(feclearexcept(FE_ALL_EXCEPT)) printf("feclearexcept(FE_ALL_EXCEPT) FAILED!!\n"); // Se limpian las excepciones
                signed2fp = (float) random_signed;
                NV = fetestexcept(FE_INVALID);
                NX = fetestexcept(FE_INEXACT);
                memset(out_str,0,sizeof(out_str));
                get_binary(out_str, &signed2fp); // Se obtiene la representación binaria del resultado
                fput_test_fp_converter(file, current_test_str, 0, 1, j, in_str, out_str, NV, NX);  // Se imprime test

                // {option, integer_is_signed} = {1, 0}: fp2unsigned
                if(feclearexcept(FE_ALL_EXCEPT)) printf("feclearexcept(FE_ALL_EXCEPT) FAILED!!\n"); // Se limpian las excepciones
                fp2unsigned = (unsigned int) random_float;
                NV = fetestexcept(FE_INVALID);
                NX = fetestexcept(FE_INEXACT);
                // Inicio: Manejando los resultados de intel
                if( (fp2unsigned != (unsigned int) (rintf(random_float))) & rintf(random_float)>=0 ) fp2unsigned = (unsigned int) (rintf(random_float));
                if(random_float >= 4294967168.0 | isnanf(random_float)) {fp2unsigned = 4294967295; NV = 1;}
                if(random_float < 0.0) {fp2unsigned = 0; NV = 1;}
                //--- Fin: Manejando los resultados de intel
                memset(out_str,0,sizeof(out_str));
                get_binary(out_str, &fp2unsigned); // Se obtiene la representación binaria del resultado
                fput_test_fp_converter(file, current_test_str, 1, 0, j, in_str, out_str, NV, NX);  // Se imprime test
                
                // {option, integer_is_signed} = {1, 1}: fp2signed
                if(feclearexcept(FE_ALL_EXCEPT)) printf("feclearexcept(FE_ALL_EXCEPT) FAILED!!\n"); // Se limpian las excepciones
                fp2signed = (int) random_float;
                NV = fetestexcept(FE_INVALID);
                NX = fetestexcept(FE_INEXACT);
                // Inicio: Manejando los resultados de intel
                if(fp2signed != (int) (rintf(random_float)) ) fp2signed = (int) (rintf(random_float));
                if(random_float >= 2147483648.0 | isnanf(random_float)) fp2signed = 2147483647;
                //--- Fin: Manejando los resultados de intel
                memset(out_str,0,sizeof(out_str));
                get_binary(out_str, &fp2signed); // Se obtiene la representación binaria del resultado
                fput_test_fp_converter(file, current_test_str, 1, 1, j, in_str, out_str, NV, NX);  // Se imprime test
            }
            // Titulo de cierre del set de pruebas
            fputs(test_title___end, file);
        }
    }
    /* falta agregar casos borde a mano */
    fputs("        $display(\"Total errors found: \%d (\%f percentage)\", out_errors+NV_errors+NX_errors, (out_errors+NV_errors+NX_errors)*100.0/", file);
    sprintf(percentage_info, "%d", (num_tests-num_tests_discarded)*4*4*3); fputs(percentage_info, file); memset(percentage_info,0,sizeof(percentage_info)); sprintf(percentage_info, "%d", (num_tests-num_tests_discarded)*4*4);
    fputs(");\n        $display(\"Total out_errors errors found: \%d (\%f percentage)\", out_errors, out_errors*100.0/", file); fputs(percentage_info, file);
    fputs(");\n        $display(\"Total NV_errors errors found: \%d (\%f percentage)\", NV_errors, NV_errors*100.0/", file); fputs(percentage_info, file);
    fputs(");\n        $display(\"Total NX_errors errors found: \%d (\%f percentage)\", NX_errors, NX_errors*100.0/", file); fputs(percentage_info, file);
    fputs(");\n        $display(\"Minimum elapsed time: %d\", min_elapsed_time);\n", file); fputs("        $display(\"Maximum elapsed time: %d\", max_elapsed_time);\n", file);
    fputs("        $display(\"END\"); #10 $finish;\n    end\nendmodule", file);
    fclose(file); fesetround(original_rounding);
    printf("N° of tests written: %d\nOperation ready, file generated: tb_fp_arithmetic_unit.sv\n", (num_tests-num_tests_discarded)*4*4);
    return 0;
}