from enum import IntEnum
from typing import cast
from compiler.objects import Line, Inst, Directive
from math import ceil

class WriteModes(IntEnum):
    BIN = 1
    HEX = 2

class Assembler:
    def __init__(self, outfile, dry_run, instructions: list[Line], mem_size=65536, mode=WriteModes.HEX):
        self.outfile = outfile
        self.dry_run = dry_run
        self.write_mode = mode
        self.instructions = instructions

        # note that a memory block is 16 bits (2 bytes)
        # if we're working on 64K addresses and byte level per cell in this code
        # we need to "double" mem size for proper file sizes
        self.file_buffer = [0]*(mem_size*2)

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
        inst.encoded = cast(int,encoded)

    def assemble(self):
        for line in self.instructions:
            if isinstance(line, Directive) and not line._ENCODABLE:
                continue
            # currently not supporting encodable directives
            elif isinstance(line, Inst):
                self.encode_instruction(line)

    def write_file_bin(self, chunk_bytes = 4):
        def write_fn():
            for i in range(0,len(self.file_buffer), chunk_bytes):
                chunk = 0
                for x in range(chunk_bytes):
                    chunk += self.file_buffer[i+x] << 8*(chunk_bytes-1-x)
        
                yield chunk.to_bytes(chunk_bytes)
        return 'wb', write_fn

    def write_file_hex(self, read_bytes=2):
        def write_fn():
            parity = False
            for i in range(0,len(self.file_buffer), read_bytes):
                chunk = 0
                for x in range(read_bytes):
                    chunk += self.file_buffer[i+x] << 8*(read_bytes-1-x)
                write_chunk = f'{chunk:0={2*read_bytes}x}'
                if not parity:
                    write_chunk += ' '
                else:
                    write_chunk += '\n'
                parity = not parity
                yield write_chunk
        return 'w', write_fn

    def _write_file_generator(self, write_fn, outfile):
        for blob in write_fn():
            if outfile:
                outfile.write(blob)

    def _write_file(self, writer):
        write_mode, write_fn = writer()
        if not self.dry_run:
            with open(self.outfile, write_mode) as f:
                self._write_file_generator(write_fn, f)
        else:
            self._write_file_generator(write_fn, None)

    def prepare_write_buffer(self):
        write_address = 0
        for inst in self.instructions:
            if not inst._ENCODABLE:
                continue

            inst_bytes = ceil(cast(int,  inst.encoded).bit_length() / 8.0)
            write_bytes = cast(int,inst.encoded).to_bytes(inst_bytes)
            write_address = inst.address
            for i, byte in enumerate(write_bytes):
                # note we're writing "bytes" here as well, but addressing in 2-byte
                # word space -> we need to double write_address here as well
                self.file_buffer[write_address*2 + i] = byte

    def write_file(self):
        self.assemble()
        self.prepare_write_buffer()
        if self.write_mode == WriteModes.HEX:
            self._write_file(self.write_file_hex)
        elif self.write_mode == WriteModes.BIN:
            self._write_file(self.write_file_bin)