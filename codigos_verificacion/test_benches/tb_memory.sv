/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021
*/
`timescale 1ns / 1ps

module tb_memory;

    // Inputs
    reg clk                        = 0;
    reg rst                        = 0;
    reg rw                         = 0;
    reg valid                      = 0;
    reg [31:0] addr                = 0;
    reg [31:0] data_in             = 0;
    reg [1:0] byte_half_word       = 0;
    reg is_load_unsigned           = 0;
    // Outputs
    wire ready;
    wire out_of_range;
    wire [31:0] data_out;

    // Unit under test (UUT)
    memory uut(
        // Inputs
        .clk(clk),
        .rst(rst),
        .rw(rw),
        .valid(valid),
        .addr(addr),
        .data_in(data_in),
        .byte_half_word(byte_half_word),
        .is_load_unsigned(is_load_unsigned),
        // Outputs
        .ready(ready),
        .out_of_range(out_of_range),
        .data_out(data_out)
        );
        
    always #5 clk = ~clk;
    
    // Testing
    initial begin
        // máxima dirección posible: 32'b0000000000000000_1111_0100_0001_1111
        int initial_time, elapsed_time;
        $display("\nÚltimo byte direccionable: %h\n", 32'b0000000000000000_1111_0100_0001_1111);

        // test 1: verificar señal "out_of_range"
        $display("test 1: verificar señal \"out_of_range\"");
        addr    = 32'b0000000000000000_1111_0100_0101_1111;
        data_in = 32'b01101010011100001010001100001100;
        // options    
        byte_half_word      = 2'b00;
        is_load_unsigned    = 0;
        rw      = 0;
        $display(">> addr: %h - data_in: %h", addr, data_in);  
        $display("options: load word",);
        // execution
        #10 ; initial_time = $time; valid = 1;
        while(~ready & ~out_of_range) #10;
        elapsed_time = $time-initial_time;
        $display("Initial time: %t", initial_time);
        $display("Elapsed time: %t", elapsed_time);
        // test
        if(~out_of_range)
            $display("test 1: failed\n");
        else $display("test 1: passed\n");
        #10 ; valid = 0;
        
        // test 2: gardar data (word) y leerla
        $display("test 2: gardar data (word) y leerla");
        addr    = 32'b0000000000000000_1001_0100_0001_1011;
        data_in = 32'b01101010011100001010001100001100;
        // options       
        byte_half_word      = 2'b00;
        is_load_unsigned    = 0;
        rw      = 1;
        $display(">> addr: %h - data_in: %h", addr, data_in);  
        $display("options: store word",);
        // execution
        #10 ; initial_time = $time; valid = 1;
        while(~ready & ~out_of_range) #10;
        elapsed_time = $time-initial_time;
        $display("store - Initial time: %t", initial_time);
        $display("store - Elapsed time: %t", elapsed_time);
        #10 ; valid = 0;
        // options
        byte_half_word      = 2'b00;
        is_load_unsigned    = 0;   
        rw      = 0;
        $display(">> addr: %h - data_in: %h", addr, data_in);  
        $display("options: load word",);
        // execution
        #10 ; initial_time = $time; valid = 1;
        while(~ready & ~out_of_range) #10;
        elapsed_time = $time-initial_time;
        $display("load - Initial time: %t", initial_time);
        $display("load - Elapsed time: %t", elapsed_time);
        // test
        $display("data_out: %h",data_out);
        if(data_in == data_out)
            $display("test 2: passed\n");
        else $display("test 2: failed\n");
        #10 ; valid = 0;

        // test 3: gardar data (word) y leerla en el mismo bloque cache del test 2 pero otra palabra
        $display("test 3: gardar data (word) y leerla en el mismo bloque cache del test 2 pero otra palabra");
        addr    = 32'b0000000000000000_1001_0100_0001_1111;
        data_in = 32'b011000110011100101000001100001100;
        // options       
        byte_half_word      = 2'b00;
        is_load_unsigned    = 0;
        rw      = 1;
        $display(">> addr: %h - data_in: %h", addr, data_in);  
        $display("options: store word",);
        // execution
        #10 ; initial_time = $time; valid = 1;
        while(~ready & ~out_of_range) #10;
        elapsed_time = $time-initial_time;
        $display("store - Initial time: %t", initial_time);
        $display("store - Elapsed time: %t", elapsed_time);
        #10 ; valid = 0;
        // options
        byte_half_word      = 2'b00;
        is_load_unsigned    = 0;   
        rw      = 0;
        $display(">> addr: %h - data_in: %h", addr, data_in);  
        $display("options: load word",);
        // execution
        #10 ; initial_time = $time; valid = 1;
        while(~ready & ~out_of_range) #10;
        elapsed_time = $time-initial_time;
        $display("load - Initial time: %t", initial_time);
        $display("load - Elapsed time: %t", elapsed_time);
        // test
        $display("data_out: %h",data_out);
        if(data_in == data_out)
            $display("test 3: passed\n");
        else $display("test 3: failed\n");
        #10 ; valid = 0;

        // test 4: leer la palabra almacenada en el test 2 (para comprobar que se haya almacenado correctamente despues de los tests anteriores)
        $display("test 4: leer la palabra almacenada en el test 2 (para comprobar que se haya almacenado correctamente despues de los tests anteriores)");
        addr    = 32'b0000000000000000_1001_0100_0001_1011;
        data_in = 32'b011000110011100101000001100001100;
        // options       
        byte_half_word      = 2'b00;
        is_load_unsigned    = 0;  
        rw      = 0;
        $display(">> addr: %h - data_in: %h", addr, data_in);  
        $display("options: load word",);
        // execution
        #10 ; initial_time = $time; valid = 1;
        while(~ready & ~out_of_range) #10;
        elapsed_time = $time-initial_time;
        $display("load - Initial time: %t", initial_time);
        $display("load - Elapsed time: %t", elapsed_time);
        // test
        $display("data_out: %h",data_out);
        if(data_out == 32'b01101010011100001010001100001100)
            $display("test 4: passed\n");
        else $display("test 4: failed\n");
        #10 ; valid = 0;

        // test 5: leer un byte signed
        $display("test 5: leer un byte signed");
        addr    = 32'b0000000000000000_1001_0100_0001_1011;
        data_in = 32'b011000110011100101000001100001100;
        // options       
        byte_half_word      = 2'b10;
        is_load_unsigned    = 0;  
        rw      = 0;
        $display(">> addr: %h - data_in: %h", addr, data_in);  
        $display("options: load byte signed",);
        // execution
        #10 ; initial_time = $time; valid = 1;
        while(~ready & ~out_of_range) #10;
        elapsed_time = $time-initial_time;
        $display("load - Initial time: %t", initial_time);
        $display("load - Elapsed time: %t", elapsed_time);
        // test
        $display("data_out: %h",data_out);
        if(data_out == 32'b000000000000000000000000_01101010)
            $display("test 5: passed\n");
        else $display("test 5: failed\n");
        #10 ; valid = 0;

        // test 6: leer un byte signed
        $display("test 6: leer un byte signed");
        addr    = 32'b0000000000000000_1001_0100_0001_1001;
        data_in = 32'b011000110011100101000001100001100;
        // options       
        byte_half_word      = 2'b10;
        is_load_unsigned    = 0;  
        rw      = 0;
        $display(">> addr: %h - data_in: %h", addr, data_in);  
        $display("options: load byte signed",);
        // execution
        #10 ; initial_time = $time; valid = 1;
        while(~ready & ~out_of_range) #10;
        elapsed_time = $time-initial_time;
        $display("load - Initial time: %t", initial_time);
        $display("load - Elapsed time: %t", elapsed_time);
        // test
        $display("data_out: %h",data_out);
        if(data_out == 32'b111111111111111111111111_10100011)
            $display("test 6: passed\n");
        else $display("test 6: failed\n");
        #10 ; valid = 0;

        // test 7: leer el mismo byte anterior pero unsigned
        $display("test 7: leer el mismo byte anterior pero unsigned");
        addr    = 32'b0000000000000000_1001_0100_0001_1001;
        data_in = 32'b011000110011100101000001100001100;
        // options       
        byte_half_word      = 2'b10;
        is_load_unsigned    = 1;  
        rw      = 0;
        $display(">> addr: %h - data_in: %h", addr, data_in);  
        $display("options: load byte unsigned",);
        // execution
        #10 ; initial_time = $time; valid = 1;
        while(~ready & ~out_of_range) #10;
        elapsed_time = $time-initial_time;
        $display("load - Initial time: %t", initial_time);
        $display("load - Elapsed time: %t", elapsed_time);
        // test
        $display("data_out: %h",data_out);
        if(data_out == 32'b000000000000000000000000_10100011)
            $display("test 7: passed\n");
        else $display("test 7: failed\n");
        #10 ; valid = 0;

        // test 8: ahora se modifica el byte leido en los test 6 y 7, luego se lee
        $display("test 8: ahora se modifica el byte leido en los test 6 y 7, luego se lee");
        addr    = 32'b0000000000000000_1001_0100_0001_1001;
        data_in = 32'b0110001100111001010000011_11111100;
        // options       
        byte_half_word      = 2'b10;
        is_load_unsigned    = 0;
        rw      = 1;
        $display(">> addr: %h - data_in: %h", addr, data_in);  
        $display("options: store byte",);
        // execution
        #10 ; initial_time = $time; valid = 1;
        while(~ready & ~out_of_range) #10;
        elapsed_time = $time-initial_time;
        $display("store - Initial time: %t", initial_time);
        $display("store - Elapsed time: %t", elapsed_time);
        #10 ; valid = 0;
        // options
        byte_half_word      = 2'b10;
        is_load_unsigned    = 1;   
        rw      = 0;
        $display(">> addr: %h - data_in: %h", addr, data_in);  
        $display("options: load byte unsigned",);
        // execution
        #10 ; initial_time = $time; valid = 1;
        while(~ready & ~out_of_range) #10;
        elapsed_time = $time-initial_time;
        $display("load - Initial time: %t", initial_time);
        $display("load - Elapsed time: %t", elapsed_time);
        // test
        $display("data_out: %h",data_out);
        if(data_out == 32'b000000000000000000000000_11111100)
            $display("test 8: passed\n");
        else $display("test 8: failed\n");
        #10 ; valid = 0;

        // test 9: se comprueba que la palabra donde se almacena el byte modificado en el test 8 mantenga el resto de sus bits en orden
        $display("test 9: se comprueba que la palabra donde se almacena el byte modificado en el test 8 mantenga el resto de sus bits en orden");
        addr    = 32'b0000000000000000_1001_0100_0001_1001;
        data_in = 32'b011000110011100101000001100001100;
        // options       
        byte_half_word      = 2'b00;
        is_load_unsigned    = 1;  
        rw      = 0;
        $display(">> addr: %h - data_in: %h", addr, data_in);  
        $display("options: load word",);
        // execution
        #10 ; initial_time = $time; valid = 1;
        while(~ready & ~out_of_range) #10;
        elapsed_time = $time-initial_time;
        $display("load - Initial time: %t", initial_time);
        $display("load - Elapsed time: %t", elapsed_time);
        // test
        $display("data_out: %h",data_out);
        if(data_out == 32'b0110101001110000_11111100_00001100)
            $display("test 9: passed\n");
        else $display("test 9: failed\n");
        #10 ; valid = 0;

        // test 10: se cambian los bits del tag c/r a la dirección del test 9 y se guarda un halfword, luego se lee el word
        $display("test 10: se cambian los bits del tag c/r a la dirección del test 9 y se guarda un halfword, luego se lee el word");
        addr    = 32'b0000000000000000_0001_0100_0001_1001;
        data_in = 32'b011000110011100101000001100001100;
        // options       
        byte_half_word      = 2'b01;
        is_load_unsigned    = 0;
        rw      = 1;
        $display(">> addr: %h - data_in: %h", addr, data_in);  
        $display("options: store halfword",);
        // execution
        #10 ; initial_time = $time; valid = 1;
        while(~ready & ~out_of_range) #10;
        elapsed_time = $time-initial_time;
        $display("store - Initial time: %t", initial_time);
        $display("store - Elapsed time: %t", elapsed_time);
        #10 ; valid = 0;
        // options
        byte_half_word      = 2'b00;
        is_load_unsigned    = 1;   
        rw      = 0;
        $display(">> addr: %h - data_in: %h", addr, data_in);  
        $display("options: load word",);
        // execution
        #10 ; initial_time = $time; valid = 1;
        while(~ready & ~out_of_range) #10;
        elapsed_time = $time-initial_time;
        $display("load - Initial time: %t", initial_time);
        $display("load - Elapsed time: %t", elapsed_time);
        // test
        $display("data_out: %h",data_out);
        if(data_out == 32'b0000000000000000_1000001100001100)
            $display("test 10: passed\n");
        else $display("test 10: failed\n");
        #10 ; valid = 0;

        // test 11: se vuelve a usar la dirección del test 9 para leer el halfword almacenada en dicha dirección
        $display("test 11: se vuelve a usar la dirección del test 9 para leer el halfword almacenada en dicha dirección");
        addr    = 32'b0000000000000000_1001_0100_0001_1001;
        data_in = 32'b011000110011100101000001100001100;
        // options       
        byte_half_word      = 2'b01;
        is_load_unsigned    = 1;  
        rw      = 0;
        $display(">> addr: %h - data_in: %h", addr, data_in);  
        $display("options: load halfword unsigned",);
        // execution
        #10 ; initial_time = $time; valid = 1;
        while(~ready & ~out_of_range) #10;
        elapsed_time = $time-initial_time;
        $display("load - Initial time: %t", initial_time);
        $display("load - Elapsed time: %t", elapsed_time);
        // test
        $display("data_out: %h",data_out);
        if(data_out == 32'b0000000000000000_11111100_00001100)
            $display("test 11: passed\n");
        else $display("test 11: failed\n");
        #10 ; valid = 0;

        // test 12: misma operación del test 11 pero con signo
        $display("test 12: misma operación del test 11 pero con signo");
        addr    = 32'b0000000000000000_1001_0100_0001_1001;
        data_in = 32'b011000110011100101000001100001100;
        // options       
        byte_half_word      = 2'b01;
        is_load_unsigned    = 0;  
        rw      = 0;
        $display(">> addr: %h - data_in: %h", addr, data_in);  
        $display("options: load halfword signed",);
        // execution
        #10 ; initial_time = $time; valid = 1;
        while(~ready & ~out_of_range) #10;
        elapsed_time = $time-initial_time;
        $display("load - Initial time: %t", initial_time);
        $display("load - Elapsed time: %t", elapsed_time);
        // test
        $display("data_out: %h",data_out);
        if(data_out == 32'b1111111111111111_11111100_00001100)
            $display("test 12: passed\n");
        else $display("test 12: failed\n");
        #10 ; valid = 0;


        #10 $finish;
        
    end 

endmodule