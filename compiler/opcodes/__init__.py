from .alu import mnemonics as alu_mnemonics
from .jmp import mnemonics as jmp_mnemonics
from .mem import mnemonics as mem_mnemonics
from .io import mnemonics as io_mnemonics

OPCODES = {
    **alu_mnemonics,
    **jmp_mnemonics,
    **mem_mnemonics,
    **io_mnemonics
}