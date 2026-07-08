from enum import IntEnum
from typing import cast
from compiler.objects import Line, Inst, Directive
from math import ceil

class WriteModes(IntEnum):
    BIN = 1
    HEX = 2
    EXE = 3

WORD_BYTES = 2
WORD_SIZE = WORD_BYTES*8  # note must be a multiple of 8

class Assembler:
    def __init__(self, outfile, dry_run, instructions: list[Line], mem_size=65536, mode=WriteModes.HEX):
        self.outfile = outfile
        self.dry_run = dry_run
        self.write_mode = mode
        self.instructions = instructions

        self.file_buffer = [0]*mem_size

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
            line.encode()
            # elif isinstance(line, Inst):
            #     inst.
            #     self.encode_instruction(line)

    # note for all writers -> writing hap
    def write_file_bin(self, chunk_words = 4):
        def write_fn():
            for i in range(0,len(self.file_buffer), chunk_words):
                chunk = 0
                for x in range(chunk_words):
                    chunk += self.file_buffer[i+x] << WORD_SIZE*(chunk_words-1-x)
        
                yield chunk.to_bytes(chunk_words*WORD_BYTES)
        return 'wb', write_fn
    

    def write_file_exe(self, chunk_words=4):
        # first 2 bytes used by bootloader to chech how much to read into memory
        # basically the exe header
        data_length = len(self.file_buffer).to_bytes(2)
        # pad file buffer
        self.file_buffer += [0]*(chunk_words*WORD_BYTES - len(self.file_buffer)%(chunk_words*WORD_BYTES))
        def write_fn():
            yield data_length
            for i in range(0,len(self.file_buffer), chunk_words):
                chunk = 0
                for x in range(chunk_words):
                    chunk += self.file_buffer[i+x] << (WORD_SIZE*(chunk_words-1-x))
                yield chunk.to_bytes(chunk_words*WORD_BYTES)
        return 'wb', write_fn

    def write_file_hex(self, read_words=2):
        def write_fn():
            for i in range(0,len(self.file_buffer), read_words):
                chunk = 0
                for x in range(read_words):
                    chunk += self.file_buffer[i+x] << WORD_SIZE*(read_words-1-x)
                write_chunk = f'{chunk:0={WORD_SIZE//4*read_words+read_words-1}_x}'
                write_chunk = write_chunk.replace('_', ' ')
                write_chunk += '\n'
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

    def prepare_write_buffer(self, buffered=True):
        write_address = 0
        for inst in self.instructions:
            if not inst._ENCODABLE:
                continue

            inst_bytes = ceil(cast(int,  inst.encoded).bit_length() / 8.0)
            write_bytes = cast(int,inst.encoded).to_bytes(inst_bytes)
            if inst._MNEMONIC == 'raw':
                write_bytes = cast(int,inst.encoded).to_bytes(inst._SIZE*2)
            else:
                while len(write_bytes) % WORD_BYTES != 0:
                    write_bytes = b'\x00' + write_bytes
            write_address = inst.address
            import math
            for i in range(0, math.ceil(len(write_bytes)), WORD_BYTES):
                word = 0
                for x in range(WORD_BYTES):
                    word += write_bytes[i+x] << (WORD_BYTES-x-1)*8
                # note we're writing "bytes" here as well, but addressing in 2-byte
                # word space -> we need to double write_address here as well
                self.file_buffer[write_address+i//WORD_BYTES] = word
        if not buffered:
            # programs are assumed to start at 0
            self.file_buffer = self.file_buffer[0:write_address+i//WORD_BYTES+1]

    def write_file(self):
        self.assemble()
        if self.write_mode == WriteModes.HEX:
            self.prepare_write_buffer()
            self._write_file(self.write_file_hex)
        elif self.write_mode == WriteModes.BIN:
            self.prepare_write_buffer()
            self._write_file(self.write_file_bin)
        elif self.write_mode == WriteModes.EXE:
            self.prepare_write_buffer(False)
            self._write_file(self.write_file_exe)
        else:
            raise RuntimeError('Invalid output mode')