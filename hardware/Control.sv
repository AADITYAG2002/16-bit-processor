`include "opcode.sv"

`timescale 1ns / 100ps
`define ROM_ADDR_SIZE 4
`define ROM_DATA_SIZE 24
`define ROM_NUM_INST_SIZE 11
`define STATE_END 255

module ROM (
    input  logic [`ROM_ADDR_SIZE - 1 : 0] rom_addr,
    input  logic [                 3 : 0] param_1_addr,
    input  logic [                 3 : 0] param_2_addr,
    output logic [`ROM_DATA_SIZE - 1 : 0] CTRL
);

    logic [3 : 0] read_reg_addr, write_reg_addr;
    always_comb begin
        read_reg_addr = (param_1_addr != 4'h0) ? ((`ROM_NUM_INST_SIZE - 1) - 3 - param_1_addr) : (`ROM_NUM_INST_SIZE - 1);
        write_reg_addr = (param_2_addr != 4'h0) ? ((`ROM_NUM_INST_SIZE - 1) - param_2_addr) : (`ROM_NUM_INST_SIZE - 1);
        $display(
            "[rom]   time = %3t, rom_addr : %2h, param_1_addr : %h, read_reg_addr : %h, param_2_addr : %h, write_reg_addr : %h",
            $time, rom_addr, param_1_addr, read_reg_addr, param_2_addr, write_reg_addr);
    end
    // localparam logic [`ROM_DATA_SIZE * (`ROM_NUM_INST_SIZE + 1) - 1:0] memory = {
    localparam logic [`ROM_DATA_SIZE - 1:0] memory[`ROM_NUM_INST_SIZE] = {
        /*
         * Reg_Read, Reg_Read_Addr[2:0], Reg_Write, Reg_Write_Addr[2:0],
         * Control_Read, Control_Write, Io_Read, IR_Write, IR_Read, MDR_Read, PC_Sel[2:0],
         * ALU_In_1, ALU_In_2, ALU_Op_Sel[3:0], ALU_Out_Write
         */

        // Fetch
        `ROM_DATA_SIZE'b0_000_0_000_1_0_0_0_0_1_000_0_0_0000_0,  // MDR <- [PC]

        // Decode & Execute
        `ROM_DATA_SIZE'b1_000_1_000_0_0_0_0_0_0_000_0_0_0000_0,  // Rd <- Rs
        `ROM_DATA_SIZE'b0_000_0_000_1_0_0_1_0_0_000_0_0_0000_0,  // IR <- data
        `ROM_DATA_SIZE'b0_000_1_000_0_0_0_0_1_0_000_0_0_0000_0,  // Rd <- IR

        /* Read Register select */
        `ROM_DATA_SIZE'b0_011_0_000_0_0_0_0_0_0_000_0_0_0000_0,  // C
        `ROM_DATA_SIZE'b0_010_0_000_0_0_0_0_0_0_000_0_0_0000_0,  // B
        `ROM_DATA_SIZE'b0_001_0_000_0_0_0_0_0_0_000_0_0_0000_0,  // A

        /* Write Register select */
        `ROM_DATA_SIZE'b0_000_0_011_0_0_0_0_0_0_000_0_0_0000_0,  // C
        `ROM_DATA_SIZE'b0_000_0_010_0_0_0_0_0_0_000_0_0_0000_0,  // B
        `ROM_DATA_SIZE'b0_000_0_001_0_0_0_0_0_0_000_0_0_0000_0,  // A

        // END
        `ROM_DATA_SIZE'b0_000_0_000_0_0_0_0_0_0_001_0_0_0000_0  // NOTHING
    };

    assign CTRL = memory[rom_addr] | memory[read_reg_addr] | memory[write_reg_addr];
    // assign CTRL = memory[`ROM_DATA_SIZE*rom_addr+:`ROM_DATA_SIZE] | memory[`ROM_DATA_SIZE*read_reg_addr+:`ROM_DATA_SIZE] | memory[`ROM_DATA_SIZE*write_reg_addr+:`ROM_DATA_SIZE];
endmodule

module Control #(
    parameter unsigned DATA_WIDTH = 16
) (
    input logic                      reset_n,
    input logic                      clk,
    input logic [DATA_WIDTH - 1 : 0] MDR,
    input logic                      Z_flag,
    input logic                      C_flag,

    output logic         Reg_Read,
    output logic [2 : 0] Reg_Read_Addr,
    output logic         Reg_Write,
    output logic [2 : 0] Reg_Write_Addr,

    output logic         Control_Read,
    output logic         Control_Write,
    output logic         Io_Read,
    output logic         IR_Write,
    output logic         IR_Read,
    output logic         MDR_Read,
    output logic [2 : 0] PC_Sel,

    output logic         ALU_In_1,
    output logic         ALU_In_2,
    output logic [3 : 0] ALU_Op_Sel,
    output logic         ALU_Out_Write
);

    logic [`ROM_ADDR_SIZE - 1 : 0] rom_addr;
    logic [`ROM_DATA_SIZE - 1 : 0] CTRL;

    logic [3 : 0] param_2, param_1, param_2_addr, param_1_addr;
    logic [7 : 0] instr;

    logic [7 : 0] state, next_state;

    ROM rom (
        .rom_addr    (rom_addr),
        .param_1_addr(param_1_addr),
        .param_2_addr(param_2_addr),
        .CTRL        (CTRL)
    );


    assign {instr, param_1, param_2} = MDR;

    assign {
        Reg_Read, Reg_Read_Addr, Reg_Write, Reg_Write_Addr,
        Control_Read, Control_Write, Io_Read, IR_Write, IR_Read, MDR_Read, PC_Sel,
        ALU_In_1, ALU_In_2, ALU_Op_Sel, ALU_Out_Write
    } = CTRL;

    always_ff @(posedge clk) begin

        $display("break");
        $display(
            "[state] time = %03t, reset_n : %b, state : %d, instr : %2h rom_addr : %2h, param_1_addr : %h, param_2_addr : %h",
            $time, reset_n, state, instr, rom_addr, param_1_addr, param_2_addr);

        if (!reset_n) state <= 'hFF;
        else state <= next_state;
    end

    always_comb begin
        case (state)
            // Fetch
            0: begin
                rom_addr     = 0;
                param_1_addr = 0;
                param_2_addr = 0;
                next_state   = 1;
            end

            // Decode
            1: begin
                case (instr)

                    `NOP: begin
                        rom_addr     = `ROM_NUM_INST_SIZE - 1;
                        param_1_addr = 0;
                        param_2_addr = 0;
                        next_state   = `STATE_END;
                    end

                    `MOV: begin
                        if (param_2 == {1'b0, `IR_REG}) begin
                            rom_addr     = 2;
                            param_1_addr = 0;
                            param_2_addr = 0;
                            next_state   = 2;
                        end else begin
                            rom_addr     = 1;
                            param_1_addr = param_1;
                            param_2_addr = param_2;
                            next_state   = `STATE_END;
                        end
                    end

                    default: begin
                    end
                endcase
            end
            2: begin
                case (instr)

                    `MOV: begin
                        rom_addr     = 3;
                        param_1_addr = 0;
                        param_2_addr = param_1;
                        next_state   = `STATE_END;
                    end

                    default: begin
                    end
                endcase
            end
            // Execute Cycles

            // End / Reset Cycle
            `STATE_END: begin
                rom_addr     = `ROM_NUM_INST_SIZE - 1;
                param_1_addr = 0;
                param_2_addr = 0;
                next_state   = 0;
            end

            default: begin
            end
        endcase
    end

endmodule

