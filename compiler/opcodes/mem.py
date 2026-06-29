from compiler.objects import Inst, Operand

class BaseMEM(Inst):
    _NUM_ARGS = 2
    def __init__(self, *args):
        super().__init__(*args)
        self._mode = 3

    def _parse_args(self, args):
        self._dst = Operand.parse_operand(self, args[0], allow_register=True)
        self._arg_b = Operand.parse_operand(self, args[1], allow_literal=True, allow_register=True)

DEV_MEM = 0 << 2
DEV_PERSIST = 1 << 2

OP_LD = 0
OP_STR = 1

class LD16(BaseMEM):
    _MNEMONIC = 'ld'
    _OPCODE = DEV_MEM + OP_LD

class STR16(BaseMEM):
    _MNEMONIC = 'str'
    _OPCODE = DEV_MEM + OP_STR

class LD16P(BaseMEM):
    _MNEMONIC = 'ld.p'
    _OPCODE = DEV_PERSIST + OP_LD

class STR16P(BaseMEM):
    _MNEMONIC = 'str.p'
    _OPCODE = DEV_PERSIST + OP_STR

mnemonics = {
    LD16._MNEMONIC: LD16,
    STR16._MNEMONIC: STR16,
    LD16P._MNEMONIC: LD16P,
    STR16P._MNEMONIC: STR16P
}