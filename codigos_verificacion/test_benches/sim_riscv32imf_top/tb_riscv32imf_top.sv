/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021

para: testing_code_imf.s
*/
`timescale 1ns / 1ps

module tb_riscv32imf_top;
    reg clk, rst, start, acces_to_registers_files, is_wb_data_fp_fromEEI, do_wb_fromEEI, is_rs1_fp_fromEEI, is_rs2_fp_fromEEI;
    reg acces_to_prog_mem, prog_rw_fromEEI, prog_valid_mem_fromEEI, prog_is_load_unsigned_fromEEI;
    reg acces_to_data_mem, data_rw_fromEEI, data_valid_mem_fromEEI, data_is_load_unsigned_fromEEI;
    reg [31:0] initial_PC, prog_addr_fromEEI, prog_in_fromEEI, data_addr_fromEEI, data_in_fromEEI, wb_data_fromEEI;
    reg [1:0] prog_byte_half_word_fromEEI, data_byte_half_word_fromEEI;
    reg [4:0] rs1_add_fromEEI, rs2_add_fromEEI, wb_add_fromEEI;
    wire ready, prog_ready_toEEI, prog_out_of_range_toEEI, data_ready_toEEI, data_out_of_range_toEEI;
    wire [1:0] exit_status;
    wire [31:0] prog_out_toEEI, data_out_toEEI, rs1_toEEI, rs2_toEEI, PC;
    //riscv32imf_singlecycle
    riscv32imf_pipeline
    riscv32imf(
        // inputs
        .clk(clk), .rst(rst), .start(start), .acces_to_registers_files(acces_to_registers_files),
        .is_wb_data_fp_fromEEI(is_wb_data_fp_fromEEI), .do_wb_fromEEI(do_wb_fromEEI),
        .is_rs1_fp_fromEEI(is_rs1_fp_fromEEI), .is_rs2_fp_fromEEI(is_rs2_fp_fromEEI),
        .acces_to_prog_mem(acces_to_prog_mem), .prog_rw_fromEEI(prog_rw_fromEEI),
        .prog_valid_mem_fromEEI(prog_valid_mem_fromEEI), .prog_is_load_unsigned_fromEEI(prog_is_load_unsigned_fromEEI),
        .acces_to_data_mem(acces_to_data_mem), .data_rw_fromEEI(data_rw_fromEEI),
        .data_valid_mem_fromEEI(data_valid_mem_fromEEI), .data_is_load_unsigned_fromEEI(data_is_load_unsigned_fromEEI),
        .initial_PC(initial_PC),
        .prog_addr_fromEEI(prog_addr_fromEEI), .prog_in_fromEEI(prog_in_fromEEI),
        .data_addr_fromEEI(data_addr_fromEEI), .data_in_fromEEI(data_in_fromEEI), .wb_data_fromEEI(wb_data_fromEEI),
        .prog_byte_half_word_fromEEI(prog_byte_half_word_fromEEI), .data_byte_half_word_fromEEI(data_byte_half_word_fromEEI),
        .rs1_add_fromEEI(rs1_add_fromEEI), .rs2_add_fromEEI(rs2_add_fromEEI), .wb_add_fromEEI(wb_add_fromEEI),
        // outputs
        .ready(ready),
        .prog_ready_toEEI(prog_ready_toEEI), .prog_out_of_range_toEEI(prog_out_of_range_toEEI),
        .data_ready_toEEI(data_ready_toEEI), .data_out_of_range_toEEI(data_out_of_range_toEEI),
        .exit_status(exit_status),
        .prog_out_toEEI(prog_out_toEEI), .data_out_toEEI(data_out_toEEI), .rs1_toEEI(rs1_toEEI), .rs2_toEEI(rs2_toEEI), .PC(PC)
    );
    always #5 clk = ~clk;
    initial begin
        int prog_out_file, data_out_file, registers_file;
        string buff_str;
        {clk, rst, start, acces_to_registers_files, is_wb_data_fp_fromEEI, do_wb_fromEEI, is_rs1_fp_fromEEI, is_rs2_fp_fromEEI,
        acces_to_prog_mem, prog_rw_fromEEI, prog_valid_mem_fromEEI, prog_is_load_unsigned_fromEEI,
        acces_to_data_mem, data_rw_fromEEI, data_valid_mem_fromEEI, data_is_load_unsigned_fromEEI,
        initial_PC, prog_addr_fromEEI, prog_in_fromEEI, data_addr_fromEEI, data_in_fromEEI, wb_data_fromEEI,
        prog_byte_half_word_fromEEI, data_byte_half_word_fromEEI, rs1_add_fromEEI, rs2_add_fromEEI, wb_add_fromEEI} = 0;
        $display("\nBEGIN\n");
        prog_out_file = $fopen("prog_out.mem","w");
        data_out_file = $fopen("data_out.mem","w");
        registers_file = $fopen("registers.mem","w");
        if(prog_out_file) $display("prog_out.mem - OK: %0d", prog_out_file); else $display("prog_out.mem - FAILED: %0d", prog_out_file);
        if(data_out_file) $display("data_out.mem - OK: %0d", data_out_file); else $display("data_out.mem - FAILED: %0d", data_out_file);
        if(registers_file) $display("registers.mem - OK: %0d", registers_file); else $display("registers.mem - FAILED: %0d", registers_file);
        $display("\n");
        // Se ejecuta el programa
        #10 start = 1; while(~ready) #10;
        $display("\nexit_status: %b\n", exit_status);
        $display("\nPC: %h\n", PC+32'b100);
        #10 start = 0;
        // Se guarda el estado de la memoria de programa
        acces_to_prog_mem = 1'b1;
        while(1) begin
            #10;
            prog_valid_mem_fromEEI = 1'b1;
            while(~prog_ready_toEEI & ~prog_out_of_range_toEEI) #10;
            if(prog_out_of_range_toEEI == 1) break;
            $fwriteh(prog_out_file, prog_addr_fromEEI); $fwrite(prog_out_file, ":  ");
            $fwriteh(prog_out_file, prog_out_toEEI); $fwrite(prog_out_file, "\n");
            #10;
            prog_valid_mem_fromEEI = 1'b0;
            prog_addr_fromEEI += 4;
        end
        {prog_addr_fromEEI, acces_to_prog_mem, prog_valid_mem_fromEEI} = 0;
        // Se guarda el estado de la memoria de datos
        acces_to_data_mem = 1'b1;
        while(1) begin
            #10;
            data_valid_mem_fromEEI = 1'b1;
            while(~data_ready_toEEI & ~data_out_of_range_toEEI) #10;
            if(data_out_of_range_toEEI == 1) break;
            $fwriteh(data_out_file, data_addr_fromEEI); $fwrite(data_out_file, ":  ");
            $fwriteh(data_out_file, data_out_toEEI); $fwrite(data_out_file, "\n");
            #10;
            data_valid_mem_fromEEI = 1'b0;
            data_addr_fromEEI += 4;
        end
        {data_addr_fromEEI, acces_to_data_mem, data_valid_mem_fromEEI} = 0;
        // se guarda el estado del register files
        acces_to_registers_files = 1'b1;
        $fwrite(registers_file, "integer_regs\n");
        {is_rs1_fp_fromEEI, is_rs2_fp_fromEEI} = 2'b00;
        {rs1_add_fromEEI, rs2_add_fromEEI} = 10'b00000_00001;
        for(int i = 0; i < 16; i++) begin
            #10;
            $fwriteh(registers_file, rs1_add_fromEEI); $fwrite(registers_file, ":   ");
            $fwriteh(registers_file, rs1_toEEI); $fwrite(registers_file, "\n");
            $fwriteh(registers_file, rs2_add_fromEEI); $fwrite(registers_file, ":   ");
            $fwriteh(registers_file, rs2_toEEI); $fwrite(registers_file, "\n");
            #10;
            rs1_add_fromEEI += 5'b10;
            rs2_add_fromEEI += 5'b10;
            #10;
        end
        $fwrite(registers_file, "fp_regs\n");
        {is_rs1_fp_fromEEI, is_rs2_fp_fromEEI} = 2'b11;
        {rs1_add_fromEEI, rs2_add_fromEEI} = 10'b00000_00001;
        for(int i = 0; i < 16; i++) begin
            #10;
            $fwriteh(registers_file, rs1_add_fromEEI); $fwrite(registers_file, ":   ");
            $fwriteh(registers_file, rs1_toEEI); $fwrite(registers_file, "\n");
            $fwriteh(registers_file, rs2_add_fromEEI); $fwrite(registers_file, ":   ");
            $fwriteh(registers_file, rs2_toEEI); $fwrite(registers_file, "\n");
            #10;
            rs1_add_fromEEI += 5'b10;
            rs2_add_fromEEI += 5'b10;
            #10;
        end
        {rs1_add_fromEEI, rs2_add_fromEEI, is_rs1_fp_fromEEI, is_rs2_fp_fromEEI, acces_to_registers_files} = 0;
        // fin
        $display("\nEND\n");
        $fclose(prog_out_file); $fclose(data_out_file); $fclose(registers_file); #10 $finish;
    end
endmodule
