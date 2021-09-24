/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021

para: fibonacci_simple.s
*/
`timescale 1ns / 1ps

module tb_TOP;
    reg clk, rst_asin, start_asin, resume_asin;
    reg [15:0] in;
    wire [5:0] color_leds;
    wire [15:0] leds, display;
    TOP TOP_uut(
        .clk(clk), .rst_asin(rst_asin), .start_asin(start_asin), .resume_asin(resume_asin), .in(in),
        .color_leds(color_leds), .leds(leds), .display(display)
    );
    always #5 clk = ~clk;
    initial begin
        {clk, start_asin, resume_asin, in, rst_asin} = 20'b1;
        $display("\nBEGIN\n"); #10
        
        $display("\ncolor_leds: %b\n", color_leds);

        #100 start_asin = 1'b1; #1000000 start_asin = 1'b0; // se inicia ejecución

        while(color_leds != 6'b101_101) #10; // mientras no printe un entero se espera
        #100 resume_asin = 1'b1; #1000000 resume_asin = 1'b0; // se reanuda ejecución

        while(color_leds != 6'b101_101) #10; // mientras no printe un entero se espera
        #100 resume_asin = 1'b1; #1000000 resume_asin = 1'b0; // se reanuda ejecución

        while(color_leds != 6'b101_101) #10; // mientras no printe un entero se espera
        #100 resume_asin = 1'b1; #1000000 resume_asin = 1'b0; // se reanuda ejecución

        while(color_leds != 6'b101_101) #10; // mientras no printe un entero se espera
        #100 resume_asin = 1'b1; #1000000 resume_asin = 1'b0; // se reanuda ejecución

        while(color_leds != 6'b101_101) #10; // mientras no printe un entero se espera
        #100 resume_asin = 1'b1; #1000000 resume_asin = 1'b0; // se reanuda ejecución

        while(color_leds != 6'b101_101) #10; // mientras no printe un entero se espera
        #100 resume_asin = 1'b1; #1000000 resume_asin = 1'b0; // se reanuda ejecución

        while(color_leds != 6'b101_101) #10; // mientras no printe un entero se espera
        #100 resume_asin = 1'b1; #1000000 resume_asin = 1'b0; // se reanuda ejecución

        while(color_leds != 6'b101_101) #10; // mientras no printe un entero se espera
        #100 resume_asin = 1'b1; #1000000 resume_asin = 1'b0; // se reanuda ejecución

        while(color_leds != 6'b101_101) #10; // mientras no printe un entero se espera
        #100 resume_asin = 1'b1; #1000000 resume_asin = 1'b0; // se reanuda ejecución

        while(color_leds != 6'b101_101) #10; // mientras no printe un entero se espera
        #100 resume_asin = 1'b1; #1000000 resume_asin = 1'b0; // se reanuda ejecución

        while(color_leds != 6'b010_010) #10; // mientras no finalice

        #1000000
        
        $display("\ncolor_leds: %b\n", color_leds);

        $display("\nEND\n"); #10 $finish;
    end
endmodule
