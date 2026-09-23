`include "opcode.sv"

`timescale 1ns / 100ps
`define ROM_ADDR_SIZE 4
`define ROM_DATA_SIZE 24
`define ROM_NUM_INST_SIZE 11
`define ROM_NOTHING `ROM_NUM_INST_SIZE - 1
`define RESET 255
`define STATE_END 0

module ROM(
    input   logic   [ `ROM_ADDR_SIZE - 1 : 0 ] rom_addr      ,
    input   logic   [ 2 : 0 ]                read_addr       ,
    input   logic   [ 2 : 0 ]                write_addr      ,
    output  logic   [ `ROM_DATA_SIZE - 1 : 0 ] CTRL
);

    logic   [ 3 : 0 ] read_reg_addr, write_reg_addr;

    always_comb begin
        read_reg_addr  = ( read_addr != 3'h0 ) ? ( `ROM_NOTHING - 3 - read_addr ) : `ROM_NOTHING;
        write_reg_addr = ( write_addr != 3'h0 ) ? ( `ROM_NOTHING - write_addr ) : `ROM_NOTHING;
    end

    // localparam logic [`ROM_DATA_SIZE * (`ROM_NUM_INST_SIZE + 1) - 1:0] memory = {
    localparam logic [ `ROM_DATA_SIZE - 1 : 0 ] memory [ `ROM_NUM_INST_SIZE ] = {
    /*
         * Reg_Read, Reg_Read_Addr[2:0], Reg_Write, Reg_Write_Addr[2:0],
         * Control_Read, Control_Write, Io_Read, IR_Write, IR_Read, MDR_Read, PC_Sel[2:0],
         * ALU_In_1, ALU_In_2, ALU_Op_Sel[3:0], ALU_Out_Write
         */
    // Fetch
    `ROM_DATA_SIZE 'b0_000_0_000_1_0_0_0_0_1_001_0_0_0000_0, // MDR <- [PC]
    // Decode & Execute
    `ROM_DATA_SIZE 'b1_000_1_000_0_0_0_0_0_0_000_0_0_0000_0, // Rd <- Rs
    `ROM_DATA_SIZE 'b0_000_0_000_1_0_0_1_0_0_001_0_0_0000_0, // IR <- data
    `ROM_DATA_SIZE 'b0_000_1_000_0_0_0_0_1_0_000_0_0_0000_0, // Rd <- IR
    /* Read Register select */
    `ROM_DATA_SIZE 'b0_011_0_000_0_0_0_0_0_0_000_0_0_0000_0, // D
    `ROM_DATA_SIZE 'b0_010_0_000_0_0_0_0_0_0_000_0_0_0000_0, // C
    `ROM_DATA_SIZE 'b0_001_0_000_0_0_0_0_0_0_000_0_0_0000_0, // B
    /* Write Register select */
    `ROM_DATA_SIZE 'b0_000_0_011_0_0_0_0_0_0_000_0_0_0000_0, // D
    `ROM_DATA_SIZE 'b0_000_0_010_0_0_0_0_0_0_000_0_0_0000_0, // C
    `ROM_DATA_SIZE 'b0_000_0_001_0_0_0_0_0_0_000_0_0_0000_0, // B
    // END
    `ROM_DATA_SIZE 'b0_000_0_000_0_0_0_0_0_0_000_0_0_0000_0 // Nothing
    };

    assign CTRL     = memory[ rom_addr ] | memory[ read_reg_addr ] | memory[ write_reg_addr ];
    // assign CTRL     = memory[ `ROM_DATA_SIZE * rom_addr +: `ROM_DATA_SIZE ] | memory[ `ROM_DATA_SIZE * read_reg_addr +: `ROM_DATA_SIZE ] | memory[ `ROM_DATA_SIZE * write_reg_addr +: `ROM_DATA_SIZE ];
endmodule

module Control #(
    parameter unsigned DATA_WIDTH = 16
)(
    input   logic                            reset_n             ,
    input   logic                            clk                 ,
    input   logic   [ DATA_WIDTH - 1 : 0 ]   MDR                 ,
    input   logic                            Z_flag              ,
    input   logic                            C_flag              ,
    output  logic                            Reg_Read            ,
    output  logic   [ 2 : 0 ]                Reg_Read_Addr       ,
    output  logic                            Reg_Write           ,
    output  logic   [ 2 : 0 ]                Reg_Write_Addr      ,
    output  logic                            Control_Read        ,
    output  logic                            Control_Write       ,
    output  logic                            Io_Read             ,
    output  logic                            IR_Write            ,
    output  logic                            IR_Read             ,
    output  logic                            MDR_Read            ,
    output  logic   [ 2 : 0 ]                PC_Sel              ,
    output  logic                            ALU_In_1            ,
    output  logic                            ALU_In_2            ,
    output  logic   [ 3 : 0 ]                ALU_Op_Sel          ,
    output  logic                            ALU_Out_Write
);

    logic   [ `ROM_ADDR_SIZE - 1 : 0 ] rom_addr;
    logic   [ `ROM_DATA_SIZE - 1 : 0 ] CTRL;

    logic   [ 2 : 0 ] write_addr, read_addr, param_2, param_1;
    logic             param_2_immd, param_1_immd;
    logic   [ 7 : 0 ] instr ;

    logic   [ 7 : 0 ] state , next_state;

    ROM rom (
        .rom_addr           ( rom_addr           ),
        .read_addr          ( read_addr          ),
        .write_addr         ( write_addr         ),
        .CTRL               ( CTRL               )
    );

    assign {instr, param_1_immd, param_1, param_2_immd, param_2} = MDR;

    assign {Reg_Read, Reg_Read_Addr, Reg_Write, Reg_Write_Addr, Control_Read, Control_Write, Io_Read, IR_Write, IR_Read, MDR_Read, PC_Sel, ALU_In_1, ALU_In_2, ALU_Op_Sel, ALU_Out_Write} = CTRL;

    always_ff @( posedge clk ) begin
        if ( !reset_n )
            state    <= 'hFF;
        else
            state    <= next_state;
    end

    always_comb begin
        case ( state )
            // Fetch
            0: begin
                rom_addr   = 0;
                write_addr = 0;
                read_addr  = 0;
                next_state = 1;
            end

            // Decode & Execute
            1: begin
                case ( instr )

                    `NOP : begin
                        rom_addr   = `ROM_NOTHING;
                        write_addr = 0;
                        read_addr  = 0;
                        next_state = `STATE_END;
                    end

                    `MOV
                    : begin
                        if ( param_2_immd == 1'b1 ) begin
                            rom_addr   = 2;
                            write_addr = 0;
                            read_addr  = 0;
                            next_state = 2;
                        end
                        else begin
                            rom_addr   = 1;
                            write_addr = param_1;
                            read_addr  = param_2;
                            next_state = `STATE_END;
                        end
                    end

                    default : begin
                        rom_addr   = `ROM_NOTHING;
                        write_addr = 0;
                        read_addr  = 0;
                        next_state = `STATE_END;
                    end
                endcase
            end
            2: begin
                case ( instr )

                    `MOV : begin
                        rom_addr   = 3;
                        write_addr = param_1;
                        read_addr  = 0;
                        next_state = `STATE_END;
                    end

                    default : begin
                        rom_addr   = `ROM_NOTHING;
                        write_addr = 0;
                        read_addr  = 0;
                        next_state = `STATE_END;
                    end
                endcase
            end

            // End / Reset Cycle
            `RESET
            : begin
                rom_addr   = `ROM_NOTHING;
                write_addr = 0;
                read_addr  = 0;
                next_state = 0;
            end

            default : begin
            end
        endcase
    end

endmodule
