`include "opcode.sv"

`timescale 1ns / 100ps
`define ROM_ADDR_SIZE 5
`define ROM_DATA_SIZE 18
`define ROM_NUM_INST_SIZE 16
`define ROM_NOTHING `ROM_NUM_INST_SIZE - 1
`define STATE_END 255

module ROM (
    input  logic [`ROM_ADDR_SIZE - 1 : 0] rom_addr,
    output logic [`ROM_DATA_SIZE - 1 : 0] CTRL
);
    // localparam logic [`ROM_DATA_SIZE * (`ROM_NUM_INST_SIZE + 1) - 1:0] memory = {
    localparam logic [`ROM_DATA_SIZE - 1 : 0] memory[`ROM_NUM_INST_SIZE] = {
        /*
         * Reg_Read, Reg_Write,
         * Read_Mem, Write_Mem,
         * Control_Read, Control_Write, Io_Read_Write, IR_Write, IR_Read, CIR_Write, MDR_Read, MDR_Write, MAR_Write,
         * PC_Sel[2:0],
         * ALU_in_B_sel, ALU_Out_Write
         */

        // Fetch Instruction
        /* 0  */ `ROM_DATA_SIZE'b0_0_0_0_0_0_0_0_0_0_0_0_1_001_0_0,  // MAR <- PC
        /* 1  */ `ROM_DATA_SIZE'b0_0_1_0_0_0_0_0_0_0_0_0_0_000_0_0,  // address <- MAR
        /* 2  */ `ROM_DATA_SIZE'b0_0_0_0_1_0_0_0_0_0_0_0_0_000_0_0,  // MDR <- data
        /* 3  */ `ROM_DATA_SIZE'b0_0_0_0_0_0_0_0_0_1_1_0_0_000_0_0,  // CIR <- MDR

        // Load / Store Value
        /* 4  */ `ROM_DATA_SIZE'b0_0_0_0_0_0_1_0_0_0_0_0_1_000_0_0,  // MAR <- IR
        /* 5  */ `ROM_DATA_SIZE'b0_0_0_0_0_0_0_1_0_0_1_0_0_000_0_0,  // IR <- MDR
        /* 6  */ `ROM_DATA_SIZE'b0_1_0_0_0_0_0_0_0_0_1_0_0_000_0_0,  // Rd <- MDR
        /* 7  */ `ROM_DATA_SIZE'b1_0_0_0_0_0_0_0_0_0_0_1_0_000_0_0,  // MDR <- Rs
        /* 8  */ `ROM_DATA_SIZE'b0_0_0_1_0_1_0_0_0_0_0_0_0_000_0_0,  // data <- MDR

        // Decode & Execute
        /* 9  */ `ROM_DATA_SIZE'b1_1_0_0_0_0_0_0_0_0_0_0_0_000_0_0,  // Rd <- Rs
        /* 10 */ `ROM_DATA_SIZE'b0_1_0_0_0_0_0_0_1_0_0_0_0_000_0_0,  // Rd <- IR
        /* 11 */ `ROM_DATA_SIZE'b1_0_0_0_0_0_0_1_0_0_0_0_0_000_0_0,  // IR <- Rs
        /* 12 */ `ROM_DATA_SIZE'b0_1_0_0_0_0_0_0_0_0_0_0_0_000_0_1,  // Rd <- ALU_out
        /* 13 */ `ROM_DATA_SIZE'b0_0_0_0_0_0_0_0_0_0_0_0_0_010_0_0,  // Jump
        /* 14 */ `ROM_DATA_SIZE'b0_0_0_0_0_0_0_0_0_0_0_0_0_000_1_0,  // ALU_in_B = 1


        // END / RESET
        /* 15 */ `ROM_DATA_SIZE'b0_0_0_0_0_0_0_0_0_0_0_0_0_000_0_0  // Nothing
    };

    assign CTRL = memory[rom_addr];
    // assign CTRL     = memory[ `ROM_DATA_SIZE * rom_addr +: `ROM_DATA_SIZE ] | memory[ `ROM_DATA_SIZE * read_reg_addr +: `ROM_DATA_SIZE ] | memory[ `ROM_DATA_SIZE * write_reg_addr +: `ROM_DATA_SIZE ];
endmodule

module Control #(
    parameter unsigned DATA_WIDTH = 16
) (
    input logic                      reset_n,
    input logic                      clk,
    input logic [DATA_WIDTH - 1 : 0] CIR,
    input logic [             7 : 0] Flags,


    output logic Halt,

    output logic         Reg_Read,
    output logic         Reg_Write,
    output logic [3 : 0] Reg_Read_Addr,
    output logic [3 : 0] Reg_Write_Addr,

    output logic Read_Mem,
    output logic Write_Mem,
    output logic Control_Read,
    output logic Control_Write,
    output logic Io_Read_Write,
    output logic IR_Write,
    output logic IR_Read,
    output logic CIR_Write,
    output logic MDR_Read,
    output logic MDR_Write,
    output logic MAR_Write,

    output logic [2 : 0] PC_Sel,
    output logic         PC_Jump,

    output logic         ALU_Enable,
    output logic [4 : 0] ALU_Op_Sel,
    output logic         ALU_in_B_Sel,
    output logic         ALU_Out_Write
);

    logic [`ROM_ADDR_SIZE - 1 : 0] rom_addr;
    logic [`ROM_DATA_SIZE - 1 : 0] CTRL;

    logic [3 : 0] dest_reg, src_reg;
    logic [1 : 0] mode;
    logic immd;
    logic [4 : 0] opcode;

    logic [7 : 0] state, next_state;

    ROM rom (
        .rom_addr(rom_addr),
        .CTRL    (CTRL)
    );

    assign {mode, immd, opcode, dest_reg, src_reg} = CIR;

    assign {Reg_Read, Reg_Write,
            Read_Mem, Write_Mem, Control_Read, Control_Write, Io_Read_Write, IR_Write, IR_Read,
            CIR_Write, MDR_Read, MDR_Write, MAR_Write,
            PC_Sel, ALU_in_B_Sel, ALU_Out_Write} = CTRL;

    always_comb begin
        if ((state == 4) && (mode == `DATA_MODE) && (opcode == `STA)) begin
            Reg_Read_Addr  = dest_reg;
            Reg_Write_Addr = `A_REG;
        end else begin
            Reg_Read_Addr  = src_reg;
            Reg_Write_Addr = dest_reg;
        end
    end

    assign ALU_Op_Sel = ((mode == `DATA_MODE) && (opcode == `PUSH)) ?
        `SUB
        : ((mode == `DATA_MODE) && (opcode == `POP)) ?
        `ADD
        : opcode;

    assign ALU_Enable = ((mode == `DATA_MODE) && ((opcode == `PUSH) || (opcode == `POP)))
                            ? 1 : (mode == `ALU_MODE);

    always_comb begin
        logic c_flag, z_flag;
        {c_flag, z_flag} = Flags[1:0];
        if ((mode == `JUMP_MODE) && (state == 8)) begin
            case (opcode)
                `JUMP: PC_Jump = 1;
                `JUMP_NZ: PC_Jump = !z_flag;
                `JUMP_Z: PC_Jump = z_flag;
                `JUMP_NC: PC_Jump = !c_flag;
                `JUMP_C: PC_Jump = c_flag;
                default: PC_Jump = 0;
            endcase
        end else PC_Jump = 0;
    end

    always_ff @(posedge clk) begin
        if (!reset_n) state <= `STATE_END;
        else state <= next_state;
    end

    always_ff @(posedge clk) begin
        if (!reset_n) Halt <= 0;
        else if ((state == `STATE_END) && (mode == `IO_MODE) && (opcode == `HLT)) Halt <= 1;
    end

    always_latch begin
        if (!Halt) begin
            case (state)
                // Fetch
                0: begin
                    rom_addr   = 0;
                    next_state = 1;
                end
                1: begin
                    rom_addr   = 1;
                    next_state = 2;
                end
                2: begin
                    rom_addr   = 2;
                    next_state = 3;
                end
                3: begin
                    rom_addr   = 3;
                    next_state = 4;
                end

                // Decode & Execute
                4: begin
                    case (mode)
                        `IO_MODE: begin
                            case (opcode)
                                `NOP: begin
                                    rom_addr   = `ROM_NOTHING;
                                    next_state = `STATE_END;
                                end
                                `HLT: begin
                                    rom_addr   = `ROM_NOTHING;
                                    next_state = `STATE_END;
                                end
                                default: begin
                                end
                            endcase
                        end
                        `DATA_MODE: begin
                            case (opcode)
                                `MOV: begin
                                    rom_addr   = (immd == 1'b1) ? 0 : 9;
                                    next_state = (immd == 1'b1) ? 5 : `STATE_END;
                                end
                                `LDA: begin
                                    rom_addr   = (immd == 1'b1) ? 0 : 11;
                                    next_state = (immd == 1'b1) ? 5 : 8;
                                end
                                `STA: begin
                                    rom_addr   = (immd == 1'b1) ? 0 : 11;
                                    next_state = (immd == 1'b1) ? 5 : 8;
                                end
                                default: begin
                                end
                            endcase
                        end
                        `ALU_MODE: begin
                            case (opcode)
                                `ADD, `SUB, `MUL, `DIV, `AND, `OR, `XOR: begin
                                    rom_addr   = (immd == 1'b1) ? 2 : 5;
                                    next_state = 2;
                                end
                                `NOT, `RRS, `RRC, `LLS, `LLC: begin
                                    rom_addr   = 8;
                                    next_state = `STATE_END;
                                end
                                default: begin
                                    rom_addr   = `ROM_NOTHING;
                                    next_state = `STATE_END;
                                end
                            endcase
                        end
                        `JUMP_MODE: begin
                            rom_addr   = 0;
                            next_state = 5;
                        end
                        default: begin
                        end
                    endcase
                end
                5: begin
                    case (mode)
                        `IO_MODE: begin
                        end
                        `DATA_MODE: begin
                            case (opcode)
                                `MOV: begin
                                    rom_addr   = 1;
                                    next_state = 6;
                                end
                                `LDA: begin
                                    rom_addr   = 1;
                                    next_state = 6;
                                end
                                `STA: begin
                                    rom_addr   = 1;
                                    next_state = 6;
                                end
                                default: begin
                                end
                            endcase
                        end
                        `ALU_MODE: begin
                            case (opcode)
                                `ADD, `SUB, `MUL, `DIV, `AND, `OR, `XOR: begin
                                    rom_addr   = 8;
                                    next_state = `STATE_END;
                                end
                                default: begin
                                    rom_addr   = `ROM_NOTHING;
                                    next_state = `STATE_END;
                                end
                            endcase
                        end
                        `JUMP_MODE: begin
                            rom_addr   = 1;
                            next_state = 6;
                        end
                        default: begin
                        end
                    endcase
                end
                6: begin
                    case (mode)
                        `DATA_MODE: begin
                            case (opcode)
                                `MOV: begin
                                    rom_addr   = 2;
                                    next_state = 7;
                                end
                                `LDA: begin
                                    rom_addr   = 2;
                                    next_state = 7;
                                end
                                `STA: begin
                                    rom_addr   = 2;
                                    next_state = 7;
                                end
                                default: begin
                                end
                            endcase
                        end
                        `JUMP_MODE: begin
                            rom_addr   = 2;
                            next_state = 7;
                        end
                        default: begin
                        end
                    endcase
                end
                7: begin
                    case (mode)
                        `DATA_MODE: begin
                            case (opcode)
                                `MOV: begin
                                    rom_addr   = 6;
                                    next_state = `STATE_END;
                                end
                                `LDA: begin
                                    rom_addr   = 5;
                                    next_state = 8;
                                end
                                `STA: begin
                                    rom_addr   = 5;
                                    next_state = 8;
                                end
                                default: begin
                                end
                            endcase
                        end
                        `JUMP_MODE: begin
                            rom_addr   = 5;
                            next_state = 8;
                        end
                        default: begin
                        end
                    endcase
                end
                8: begin
                    case (mode)
                        `DATA_MODE: begin
                            case (opcode)
                                `LDA: begin
                                    rom_addr   = 4;
                                    next_state = 9;
                                end
                                `STA: begin
                                    rom_addr   = 4;
                                    next_state = 9;
                                end
                                default: begin
                                end
                            endcase
                        end
                        `JUMP_MODE: begin
                            rom_addr   = 13;
                            next_state = `STATE_END;
                        end
                        default: begin
                        end
                    endcase
                end
                9: begin
                    case (mode)
                        `DATA_MODE: begin
                            case (opcode)
                                `LDA: begin
                                    rom_addr   = 1;
                                    next_state = 10;
                                end
                                `STA: begin
                                    rom_addr   = 7;
                                    next_state = 10;
                                end
                                default: begin
                                end
                            endcase
                        end
                        default: begin
                        end
                    endcase
                end
                10: begin
                    case (mode)
                        `DATA_MODE: begin
                            case (opcode)
                                `LDA: begin
                                    rom_addr   = 2;
                                    next_state = 11;
                                end
                                `STA: begin
                                    rom_addr   = 8;
                                    next_state = `STATE_END;
                                end
                                default: begin
                                end
                            endcase
                        end
                        default: begin
                        end
                    endcase
                end
                11: begin
                    case (mode)
                        `DATA_MODE: begin
                            case (opcode)
                                `LDA: begin
                                    rom_addr   = 6;
                                    next_state = `STATE_END;
                                end
                                default: begin
                                end
                            endcase
                        end
                        default: begin
                        end
                    endcase
                end

                // End / Reset Cycle
                `STATE_END: begin
                    rom_addr   = `ROM_NOTHING;
                    next_state = 0;
                end

                default: begin
                end
            endcase
        end
    end

endmodule
