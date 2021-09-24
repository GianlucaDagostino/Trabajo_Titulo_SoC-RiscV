/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021
*/
`timescale 1ns / 1ps

module memory #(parameter initial_option=0)(
    input clk,                  // global clock
    input rst,                  // reset cache FSM
    input rw,                   // =1 -> write, =0 -> read
    input valid,                // do operation
    input [31:0] addr,          // address from cpu
    input [31:0] data_in,       // data to save
    input [1:0] byte_half_word, // Options; 00 or 11->word, 01->halfword, 10->byte
    input is_load_unsigned,     // =1 -> load is unsigned, =0 -> load is signed
    output reg ready,           // the operation is ready
    output out_of_range,        // the address is out of range
    output reg [31:0] data_out  // readed data
    );

    // para manejar el almacenamiento de datos en el always
    reg lecture_flag;

    // entradas indirectas (que pasan por always combinacional) del cache
    reg [31:0] data_to_cache;
    reg rw_to_cache;
    reg valid_to_cache;

    // conexiones desde la salida del cache al always combinacional
    wire [31:0] data_from_cache; // salida indirecta a cpu
    wire ready_from_cache; // salida indirecta a cpu
    wire [31:0] addr_from_cache; // salida indirecta a bram

    // entrada indirecta de la bram desde el cache
    wire [11:0] addr_to_bram; // esto es mas bien un indice

    // conexiones desde la salida de cache a la entrada de bram
    wire [127:0] data_from_cache_to_bram;
    wire valid_from_cache_to_bram;
    wire rw_from_cache_to_bram;

    // conexiones desde la salida de bram a la entrada de cache
    wire [127:0] data_from_bram_to_cache;
    wire ready_from_bram_to_cache;

    // Se verifica que la direccón está en el rango de la memoria ram (3906*4*4bytes = 62496bytes = 62.496KB)
    assign out_of_range = addr > 32'b1111_0100_0001_1111 ? '1 : '0;

    // Se ajusta dirección recibida por bram (recibe 14 bits de addr)
    assign addr_to_bram = addr_from_cache[15:4];

    // always necesario para manejar byte, halfword, word
    always_comb begin
        lecture_flag = 0;
        data_out = 32'b0;
        data_to_cache = 32'b0;
        rw_to_cache = 0;
        ready = 0;
        valid_to_cache = 0;
        if(~out_of_range*valid) begin
            valid_to_cache = 1;
            if(rw) begin // escritura
                if(ready_from_cache & ~lecture_flag) begin
                    data_out = data_from_cache; 
                    lecture_flag = 1;
                end
                if(lecture_flag) begin
                    valid_to_cache = 0;
                    case(byte_half_word)
                        2'b01: begin // 01->store halfword (little endian)
                            case(addr[1])
                                1'b0: data_to_cache = {data_out[31:16],data_in[15:0]};
                                1'b1: data_to_cache = {data_in[15:0],data_out[15:0]};
                            endcase
                        end
                        2'b10: begin // 10->store byte (little endian)
                            case(addr[1:0])
                                2'b00: data_to_cache = {data_out[31:8],data_in[7:0]};
                                2'b01: data_to_cache = {data_out[31:16],data_in[7:0],data_out[7:0]};
                                2'b10: data_to_cache = {data_out[31:24],data_in[7:0],data_out[15:0]};
                                2'b11: data_to_cache = {data_in[7:0],data_out[23:0]};
                            endcase
                        end
                        default: begin // 00 or 11->store word
                            data_to_cache = data_in;
                        end 
                    endcase
                    rw_to_cache = 1;
                    valid_to_cache = 1;
                    ready = ready_from_cache;
                end
            end
            else begin // lectura is_load_unsigned
                if(ready_from_cache) begin
                    case(byte_half_word)
                        2'b01: begin // 01->load halfword (little endian)
                            case(addr[1])
                                1'b0: data_out = is_load_unsigned ? 32'(unsigned'(data_from_cache[15:0]))  : 32'(signed'(data_from_cache[15:0]));
                                1'b1: data_out = is_load_unsigned ? 32'(unsigned'(data_from_cache[31:16])) : 32'(signed'(data_from_cache[31:16]));
                            endcase
                        end
                        2'b10: begin // 10->load byte (little endian)
                            case(addr[1:0])
                                2'b00: data_out = is_load_unsigned ? 32'(unsigned'(data_from_cache[7:0]))   : 32'(signed'(data_from_cache[7:0]));
                                2'b01: data_out = is_load_unsigned ? 32'(unsigned'(data_from_cache[15:8]))  : 32'(signed'(data_from_cache[15:8]));
                                2'b10: data_out = is_load_unsigned ? 32'(unsigned'(data_from_cache[23:16])) : 32'(signed'(data_from_cache[23:16]));
                                2'b11: data_out = is_load_unsigned ? 32'(unsigned'(data_from_cache[31:24])) : 32'(signed'(data_from_cache[31:24]));
                            endcase
                        end
                        default: begin // 00 or 11->load word
                            data_out = data_from_cache;
                        end 
                    endcase
                    ready = 1;
                    valid_to_cache = 1;
                    lecture_flag = 0;
                    data_to_cache = 32'bX;
                    rw_to_cache = 0;
                end
            end
        end
        else begin
            lecture_flag = 0;
            data_out = 32'bX;
            data_to_cache = 32'bX;
            rw_to_cache = 0;
            ready = 0;
            valid_to_cache = 0;
        end
    end

    cache_controller cache_controller_unit(
        //inputs
        .clk(clk), // global clock
        .rst(rst), // reset cache
        .cpu_addr(addr), // (32 bits) address from cpu
        .cpu_data_in(data_to_cache), // (32 bits) bus dependiente de always combinacional
        .cpu_rw(rw_to_cache), // rw dependiente de always combinacional
        .cpu_valid(valid_to_cache), // valid dependiente de always combinacional
        .mem_data_in(data_from_bram_to_cache), // (128 bits) conectado directamente con la salida (data_out) de bram
        .mem_ready(ready_from_bram_to_cache), // conectado directamente con la salida (ready) de bram
        //outputs
        .cpu_data_out(data_from_cache), // (32 bits) salida que va a always combinacional
        .cpu_ready(ready_from_cache), // salida que va a always combinacional
        .mem_addr(addr_from_cache), // (32 bits) salida que va a always combinacional
        .mem_data_out(data_from_cache_to_bram), // (128 bits) conectado directamente a la entrada (data_in) de la bram
        .mem_rw(rw_from_cache_to_bram), // conectado directamente a la entrada (rw) de la bram
        .mem_valid(valid_from_cache_to_bram) // conectado directamente a la entrada (valid) de la bram
        );
    
    block_ram #(.initial_option(initial_option)) block_ram_unit(
        //inputs
        .clk(clk), // global clock
        .addr(addr_to_bram), // (14 bits) bus dependiente de always combinacional
        .data_in(data_from_cache_to_bram), // (128 bits) conectado directamente con la salida (mem_data_out) del cache
        .rw(rw_from_cache_to_bram), // conectado directamente con la salida (mem_rw) del cache
        .valid(valid_from_cache_to_bram), // conectado directamente con la salida (mem_valid) del cache
        //outputs
        .data_out(data_from_bram_to_cache), // (128 bits) conectado directamente a la entrada (mem_data_in) del cache
        .ready(ready_from_bram_to_cache) // conectado directamente a la entrada (mem_ready) del cache
        );
    
endmodule

// ram 3906*4*4bytes = 62496bytes = 62.496KB
module block_ram #(parameter initial_option=0)(
    input clk,
    input [11:0] addr,
    input [127:0] data_in,
    input rw,
    input valid,
    output reg [127:0] data_out,
    output reg ready
    );
    reg[127:0] mem[3905:0];
    initial
        if      (initial_option==1) $readmemh("data_in.mem", mem);
        else if (initial_option==2) $readmemh("text_in.mem", mem);
        else    for(int i=0; i<3906; i++) mem[i] = '0;
    always_ff @ (posedge clk) 
        if (valid) begin
            if(rw) mem[addr] = data_in;
            data_out = mem[addr];
            ready = '1;
        end
        else ready = '0;
endmodule