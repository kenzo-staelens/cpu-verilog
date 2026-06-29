from enum import IntEnum
from typing import cast
from compiler.objects import Line, Inst, Directive
from compiler.errors import CompileError

class WriteModes(IntEnum):
    BIN = 1
    HEX = 2

INST_BITS = 32

class Assembler:
    def __init__(self, outfile, dry_run, instructions: list[Line], mode=WriteModes.HEX):
        self.outfile = outfile
        self.dry_run = dry_run
        self.write_mode = mode
        self.instructions = instructions

    def encode_instruction(self, inst: Inst):
        encoded = 0
        # mode
        encoded += inst._mode << 29
        encoded += inst._immediate << 28
        encoded += inst._opcode << 24
        encoded += cast(int, inst._dst.value) << 20
        encoded += cast(int, inst._arg_a.value) << 16
        if inst._immediate:
            encoded += cast(int, inst._arg_b.value)
        else:
            encoded += cast(int, inst._arg_b.value) << 8
        inst.encoded = encoded

    def assemble(self):
        for line in self.instructions:
            if isinstance(line, Directive) and not line._ENCODABLE:
                continue
            # currently not supporting encodable directives
            elif isinstance(line, Inst):
                self.encode_instruction(line)

    def write_file_bin(self):
        def write_fn(inst):
            return inst.encoded.to_bytes(4, 'big')
        return 'wb', write_fn

    def write_file_hex(self):
        total_symbols = INST_BITS//4
        total_symbols = total_symbols + max((total_symbols-1)//4, 0)
        def write_fn(inst):
            return f'{inst.encoded:0={total_symbols}_x}'.replace('_',' ') + '\n'
        return 'w', write_fn

    def _write_file_generator(self, write_fn, outfile, verbose):
        for inst in self.instructions:
            if not inst._ENCODABLE:
                continue
            if not isinstance(inst.encoded, int):
                raise CompileError(f'failed to encode instruction\n{inst}')
            write_data = write_fn(inst)
            if outfile:
                outfile.write(write_data)
            if verbose:
                print(write_data, end='')
        if verbose:
            print()
    def _write_file(self, writer, verbose=False):
        write_mode, write_fn = writer()
        if not self.dry_run:
            with open(self.outfile, write_mode) as f:
                self._write_file_generator(write_fn, f, verbose)
        else:
            self._write_file_generator(write_fn, None, verbose)

    def write_file(self, verbose=False):
        self.assemble()
        if verbose:
            print('assembled data...\n')
        if self.write_mode == WriteModes.HEX:
            self._write_file(self.write_file_hex, verbose)
        elif self.write_mode == WriteModes.BIN:
            self._write_file(self.write_file_bin, verbose)