`timescale 1ns / 100ps

module Alu #(
    parameter unsigned DATA_WIDTH = 16
)(
    input   logic   [ DATA_WIDTH - 1 : 0 ]   A_reg           ,
    input   logic   [ DATA_WIDTH - 1 : 0 ]   B_reg           ,
    input   logic   [ 3 : 0 ]                op_select       ,
    output  logic   [ DATA_WIDTH - 1 : 0 ]   ALU_output      ,
    output  bit                              Z_flag          ,
    output  bit                              C_flag
);
    typedef enum {
        ADD     = 1,
        SUB        ,
        DIV        ,
        MUL        ,
        SHIFT_R    ,
        SHIFT_L    ,
        JNZ        ,
        JZ         ,
        JNC        ,
        JC
    } alu_op_codes_e;

    logic   [ DATA_WIDTH : 0 ] result;

    always_comb begin
        case ( op_select )
            ADD : result = A_reg + B_reg;
            SUB : result = A_reg - B_reg;
            DIV : result = A_reg / B_reg;
            MUL : result = A_reg * B_reg;
            SHIFT_L : result = A_reg << 1;
            SHIFT_R : result = A_reg >> 1;
            default : result = C_flag | A_reg;
        endcase

        ALU_output = result[ DATA_WIDTH - 1 : 0 ];
        C_flag     = result[ DATA_WIDTH ];
        Z_flag     = ( result == 0 ) ? 1'b1: 1'b0;
    end

endmodule
