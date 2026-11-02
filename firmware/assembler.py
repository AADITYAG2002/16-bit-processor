#!/usr/bin/env python3

import argparse
import re
import sys

OPCODES = {
    "NOP": (0b00, 0b00000),
    "HLT": (0b00, 0b11111),
    "MOV": (0b01, 0b00001),
    "LDA": (0b01, 0b00010),
    "STA": (0b01, 0b00011),
    "PUSH": (0b01, 0b00100),
    "POP": (0b01, 0b00101),
    "ADD": (0b10, 0b00000),
    "SUB": (0b10, 0b00001),
    "MUL": (0b10, 0b00010),
    "DIV": (0b10, 0b00011),
    "AND": (0b10, 0b10000),
    "OR": (0b10, 0b10001),
    "XOR": (0b10, 0b10010),
    "NOT": (0b10, 0b10011),
    "RRS": (0b10, 0b10100),
    "RRC": (0b10, 0b10101),
    "LLS": (0b10, 0b10110),
    "LLC": (0b10, 0b10111),
    "JMP": (0b11, 0b00000),
    "JNZ": (0b11, 0b00001),
    "JZ": (0b11, 0b00010),
    "JNC": (0b11, 0b00011),
    "JC": (0b11, 0b00100),
    "CALL": (0b11, 0b10000),
    "RET": (0b11, 0b10001),
}

REGISTERS = {
    "A": 0b0000,
    "B": 0b0001,
    "C": 0b0010,
    "D": 0b0011,
    "E": 0b0100,
    "SP": 0b1101,
    "PC": 0b1110,
}


class AssemblyParser:
    def __init__(self):
        self.labels = {}
        self.orgs = []
        self.addr = 0
        self.lines = []
        self.src_file = None
        self.label = re.compile(r"(\w+):", re.M)
        self.preprocessor = re.compile(r"\.(\w+) +(\w+)", re.M)
        self.immd_value = re.compile(
            r"[-+]?(\w{2,}|0[xX][\dA-Fa-f]+|0[0-7]*|\d+)$", re.M
        )
        self.instr = re.compile(r"(\w+) *(\w*)( *, *|)(\w*)", re.M)

    def parse_file(self, src_files_name: str) -> None:
        with open(src_files_name, "rt") as f:
            self.src_file = f.read()
        self.clean_file()
        self.assemble_file()
        self.src_file = None

    def clean_file(self):
        self.src_file = re.sub(r"(//|;).*", "", str(self.src_file))
        self.src_file = re.sub(r"(?s)/\*.*\*/", "", str(self.src_file))
        self.src_file = re.sub(r"(?m)^ *| *$", "", str(self.src_file))
        self.src_file = re.sub(r"[^:.\w\d]*\n", "\n", str(self.src_file))
        self.lines = re.findall(r".+", str(self.src_file))

        for line in self.lines:
            if match := self.preprocessor.search(line):
                if match[1] == "org":
                    self.addr = int(match[2], 0)

            elif match := self.label.search(line):
                self.labels[match[1]] = self.addr

            elif match := self.instr.search(line):
                self.addr += 1
                if immd_match := self.immd_value.search(match[0][match.end(1) :]):
                    self.addr += 1

            else:
                print("unknown instruction")
        self.addr = 0

    def assemble_file(self):
        for line in self.lines:
            if match := self.preprocessor.search(line):
                if match[1] == "org":
                    self.addr = int(match[2], 0)

            elif match := self.label.search(line):
                pass

            elif match := self.instr.search(line):
                mode, opcode = OPCODES[match[1].upper()]
                immd_bit = 0b0
                immd_val = 0
                if immd_match := self.immd_value.search(match[0][match.end(1) :]):
                    immd_bit = 0b1
                    if label := self.labels.get(immd_match[0]):
                        immd_val = label
                    else:
                        immd_val = int(immd_match[0], 0)

                dest_reg = REGISTERS.get(match[2].upper())
                if not dest_reg:
                    dest_reg = 0
                src_reg = REGISTERS.get(match[4].upper())
                if not src_reg:
                    src_reg = 0

                hex_val = (
                    (mode << 14)
                    | (immd_bit << 13)
                    | (opcode << 8)
                    | (dest_reg << 4)
                    | src_reg
                )
                print(f"{self.addr:04X} : {hex_val:04X}")
                self.addr += 1
                if immd_bit:
                    print(f"{self.addr:04X} : {immd_val:04X}")
                    self.addr += 1

            else:
                print("unknown instruction")


cmd_parser = argparse.ArgumentParser()
cmd_parser.add_argument(
    "inputs", metavar="INPUT", nargs="*", help="input files to assemble"
)

if __name__ == "__main__":
    assembly_parser = AssemblyParser()
    args = cmd_parser.parse_args()

    for file in args.inputs:
        assembly_parser.parse_file(src_files_name=file)
