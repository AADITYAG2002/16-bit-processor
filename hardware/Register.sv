`timescale 1ns / 100ps

typedef struct packed {
    logic   [ 16 - 1 : 0 ] SP;
    logic   [ 16 - 1 : 0 ] PC;
    logic   [ 16 - 1 : 0 ] E_reg;
    logic   [ 16 - 1 : 0 ] D_reg;
    logic   [ 16 - 1 : 0 ] C_reg;
    logic   [ 16 - 1 : 0 ] B_reg;
} register_def_t;

typedef union packed {
    register_def_t    reg_list;
    logic   [ 6 * 16 - 1 : 0 ] reg_array;
} register_file_t;

module Register #(
    parameter unsigned DATA_WIDTH = 16
)(
    input                                    clk             ,
    input   logic                            write           ,
    input   logic                            read            ,
    input   logic                            reset_n         ,
    input   logic   [ 2 : 0 ]                addr_read       ,
    input   logic   [ 2 : 0 ]                addr_write      ,
    input   logic   [ DATA_WIDTH - 1 : 0 ]   data_write      ,
    output  logic   [ DATA_WIDTH - 1 : 0 ]   data_read
);

    // logic [4 * DATA_WIDTH - 1 : 0] register;
    register_file_t   register_file;

    // debug
    logic   [ 16 - 1 : 0 ] B_reg_debug;
    logic   [ 16 - 1 : 0 ] C_reg_debug;
    logic   [ 16 - 1 : 0 ] D_reg_debug;
    logic   [ 16 - 1 : 0 ] E_reg_debug;
    // logic [4 * 16 - 1 : 0] reg_array_debug;

    assign B_reg_debug = register_file.reg_list.B_reg;
    assign C_reg_debug = register_file.reg_list.C_reg;
    assign D_reg_debug = register_file.reg_list.D_reg;
    assign E_reg_debug = register_file.reg_list.E_reg;
    // assign reg_array_debug = register.reg_array;

    always @( posedge clk ) begin
        if ( !reset_n )
            register_file <= 'b0;
        else if ( write )
            register_file [ DATA_WIDTH * ( addr_write - 1 ) +: DATA_WIDTH ] <= data_write;
    end

    assign data_read = read ? register_file[ DATA_WIDTH * ( addr_read - 1 ) +: DATA_WIDTH ] : {DATA_WIDTH {1'hz}};

endmodule
