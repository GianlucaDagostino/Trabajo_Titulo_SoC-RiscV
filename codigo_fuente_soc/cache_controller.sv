/*
autor: Gianluca Vincenzo D'Agostino Matute
Santiago de Chile, Septiembre 2021

THIS CODE WAS EXTRACTED FROM: D. A. Patterson and J. L. Hennessy, ``Computer Organization and Design, The Hardware Software/Interface: RISC-V Edition''. Cambridge, Estados Unidos: Morgan Kaufmann, 2018.
*/

`timescale 1ns / 1ps

// Data structures for cache tad & data
    
parameter int TAGMSB = 31; // tag msb
parameter int TAGLSB = 14; // tag lsb

// Data structure for cache tag
typedef struct packed{
    bit valid;              // valid bit
    bit dirty;              // dirty bit
    bit [TAGMSB:TAGLSB]tag; // tag bits
} cache_tag_type;

// Data structure fot cache memory request
typedef struct{
    bit [9:0]index; // 10-bit index
    bit we;         // write enable
} cache_req_type;

// 128-bit cache line data
typedef bit [127:0]cache_data_type;

// Data structures for CPU <-> Cache controller interface

// CPU request (CPU -> cache controller)
typedef struct{
    bit [31:0]addr; // 32-bit request addr
    bit [31:0]data; // 32-bit request data (used when white)
    bit rw;         // request type: 0=read, 1=write
    bit valid;      // request is valid
} cpu_req_type;

// Cache result (cache controller -> CPU)
typedef struct{
    bit [31:0]data; // 32-bit data
    bit ready;     // result is ready
} cpu_result_type;

// Data structures for cache controller <-> memory interface

// Memory request (cache controller -> memory)
typedef struct{
    bit [31:0]addr;  // Request byte addr
    bit [127:0]data; // 128-bit request data (used when write)
    bit rw;          // request type: 0=read, 1=write
    bit valid;       // request is valid
} mem_req_type;

// Memory controller response (memory -> cache controller)
typedef struct{
    cache_data_type data; // 128-bit read back data
    bit ready;            // data is ready
} mem_data_type;

//////////////////////////////////////////////////////////////////////////////////

/* cache: data memory, single port, 1024 blocks */
module dm_cache_data(input bit clk,
                     input  cache_req_type  data_req,   // data request/command, e.g. RW. valid
                     input  cache_data_type data_write, // write port (128-bit line)
                     output cache_data_type data_read   // read port
                     );
    timeunit 1ns;
    timeprecision 1ps;
    
    cache_data_type data_mem[0:1023];        

    initial begin
        for(int i=0; i<1024; i++)
            data_mem[i] = '0;
    end
    
    assign data_read = data_mem[data_req.index];
    
    always_ff @(posedge(clk)) begin
        if(data_req.we)
            data_mem[data_req.index] <= data_write;
    end
    
endmodule

/* cache: tag memory, single port, 1024 blocks */
module dm_cache_tag(input bit clk, // write clock
                    input  cache_req_type tag_req,   // tag request/command, e.g. RW. valid
                    input  cache_tag_type tag_write, // write port
                    output cache_tag_type tag_read   // read port
                    );
    timeunit 1ns;
    timeprecision 1ps;
    
    cache_tag_type tag_mem[0:1023];

    initial begin
        for(int i=0; i<1024; i++)
            tag_mem[i] = '0;
    end
    
    assign tag_read = tag_mem[tag_req.index];
    
    always_ff @(posedge(clk)) begin
        if(tag_req.we)
            tag_mem[tag_req.index] <= tag_write;
    end

endmodule

//////////////////////////////////////////////////////////////////////////////////

/* cache finite state machine */
module dm_cache_fsm(input bit clk, input bit rst,
                    input  cpu_req_type    cpu_req,  // CPU request input   (CPU -> cache)
                    input  mem_data_type   mem_data, // memory response     (memory -> cache)
                    output mem_req_type    mem_req,  // memory request      (cache -> memory)
                    output cpu_result_type cpu_res   // CPU response output (cache -> CPU);
                    );
    timeunit 1ns;
    timeprecision 1ps;
    
    /* write clock */
    typedef enum {idle, compare_tag, allocate, write_back} cache_state_type;
    
    /* FSM register */                    
    cache_state_type vstate, rstate;
    
    /* interface signals to tag memory */
    cache_tag_type tag_read;  // tag read result
    cache_tag_type tag_write; // tag write data
    cache_req_type tag_req;   // tag request
    
    /* interface signals to cache data memory */
    cache_data_type data_read;  // data read result
    cache_data_type data_write; // data write data
    cache_req_type  data_req;   // data request
    
    /* temporary variable for cache controller result */
    cpu_result_type v_cpu_res;
    
    /* temporary variable for memorye controller request */
    mem_req_type v_mem_req;
    
    // Connect to output ports
    assign mem_req = v_mem_req; 
    assign cpu_res = v_cpu_res;
    
    always_comb begin
        
        /*--------- default values for all signals ---------*/
        
        /* no state change by default */
        vstate = rstate;
        v_cpu_res = '{0, 0};
        tag_write = '{0, 0, 0};
        
        /* read tag by default */
        tag_req.we = '0;
        /* direct map index for tag */
        tag_req.index = cpu_req.addr[13:4];
        
        /* read current cache line by default */
        data_req.we = '0;
        /* direct map index for cache data */
        data_req.index = cpu_req.addr[13:4];
        
        /* modify correct word (32-bits) based on address */
        data_write = data_read;
        case(cpu_req.addr[3:2])
            2'b00: data_write[31:0]   = cpu_req.data;
            2'b01: data_write[63:32]  = cpu_req.data;
            2'b10: data_write[95:64]  = cpu_req.data;
            2'b11: data_write[127:96] = cpu_req.data;
        endcase
        
        /* read out correct word (32-bits) from cache (to CPU) */
        case(cpu_req.addr[3:2])
            2'b00: v_cpu_res.data = data_read[31:0];
            2'b01: v_cpu_res.data = data_read[63:32];
            2'b10: v_cpu_res.data = data_read[95:64];
            2'b11: v_cpu_res.data = data_read[127:96];
        endcase
        
        /* memory request address (sampled from CPU request) */
        v_mem_req.addr = cpu_req.addr;
        /* memory request data (used in write) */
        v_mem_req.data = data_read;

        v_mem_req.rw = '0;
        v_mem_req.valid = '0; // MOD: faltaba
        
        /*--------- cache FSM ---------*/
        case(rstate)
            /* idle state */
            idle: begin
                /* if there is a CPU request, then compare cache tag */
                if(cpu_req.valid)
                    vstate = compare_tag;
            end
            /* compare_tag state */
            compare_tag: begin
                /* cache hit (tag match and cache entry is valid) */
                if(cpu_req.addr[TAGMSB:TAGLSB] == tag_read.tag && tag_read.valid) begin
                    v_cpu_res.ready = '1;
                    /* write hit */
                    if(cpu_req.rw) begin
                        /* read/modify cache line */
                        tag_req.we  = '1;
                        data_req.we = '1;
                        /* no change in tag */
                        tag_write.tag   = tag_read.tag;
                        tag_write.valid = '1;
                        /* cache line is dirty */
                        tag_write.dirty = '1;
                    end
                    /* xaction is finished */
                    vstate = cpu_req.valid ? compare_tag : idle; // MOD: original -> //vstate = idle;
                end
                /* cache miss */
                else begin
                    /* generate new tag */
                    tag_req.we      = '1;
                    tag_write.valid = '1;
                    /* new tag */
                    tag_write.tag   = cpu_req.addr[TAGMSB:TAGLSB];
                    /* cache line is dirty if write */
                    tag_write.dirty = cpu_req.rw;
                    /* generate memory request on miss */
                    v_mem_req.valid = '1;
                    /* compulsory miss or miss with clean block */
                    if(tag_read.valid == 1'b0 || tag_read.dirty == 1'b0)
                        /* wait till a new block is allocated */
                        vstate = allocate;
                    /* miss with dirty line */
                    else begin
                        /* write back address */
                        v_mem_req.addr = {tag_read.tag, cpu_req.addr[TAGLSB-1:0]};
                        v_mem_req.rw   = '1;
                        /* wait till write is completed */
                        vstate = write_back;  
                    end
                end
            end
            /* wait for allocating a new cache line */
            allocate: begin
                /* memory controller has responded */
                if(mem_data.ready) begin
                    /* re-compare tag for write miss (need modify correct word) */
                    vstate      = compare_tag;
                    data_write  = mem_data.data;
                    /* update cache line data */
                    data_req.we = '1;
                end
            end
            /* wait for writing back dirty cache line */
            write_back: begin
                /* write back is completed */
                if(mem_data.ready) begin
                    /* issue new data memory request (allocating a new line) */
                    v_mem_req.valid = '1;
                    v_mem_req.rw    = '0;
                    vstate = allocate;
                end
            end
        endcase    
    
    end
    
    always_ff @(posedge(clk)) begin
        if(rst)
            rstate <= idle; // reset to idle state
        else
            rstate <= vstate;    
    end
    
    /* connect cache tag/data memory */
    dm_cache_tag  ctag(.*);
    dm_cache_data cdata(.*);
    
endmodule

//////////////////////////////////////////////////////////////////////////////////

/* TOP MODULE OF THIS FILE */
module cache_controller(
    input clk,
    input rst,
    input [31:0] cpu_addr,
    input [31:0] cpu_data_in,
    input cpu_rw,
    input cpu_valid,
    input [127:0] mem_data_in,
    input mem_ready,
    output [31:0] cpu_data_out,
    output cpu_ready,
    output [31:0] mem_addr,
    output [127:0] mem_data_out,
    output mem_rw,
    output mem_valid
    );
    
    // Inputs
    cpu_req_type    cpu_req;
    mem_data_type   mem_data;
    
    // Outputs
    mem_req_type    mem_req;
    cpu_result_type cpu_res;
    
    // Input connections
    assign cpu_req  = '{addr:cpu_addr, data:cpu_data_in, rw:cpu_rw, valid:cpu_valid};
    assign mem_data = '{data:mem_data_in, ready:mem_ready};
    
    // Output connections
    assign mem_addr     = mem_req.addr;
    assign mem_data_out = mem_req.data;
    assign mem_rw       = mem_req.rw;
    assign mem_valid    = mem_req.valid;
    assign cpu_data_out = cpu_res.data;
    assign cpu_ready    = cpu_res.ready;
    
    // FSM
    dm_cache_fsm cache_fsm(clk, rst, cpu_req, mem_data, mem_req, cpu_res);
    
endmodule