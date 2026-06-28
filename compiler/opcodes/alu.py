from objects.instruction import Inst, Operand

class BaseAlu(Inst):
    def __init__(self, *args):
        super().__init__(*args)
        self._mode = 1

    def parse_args(self, args):
        self._dst = Operand.parse_operand(self, args[0], allow_register=True)
        self._arg_a = Operand.parse_operand(self, args[1], allow_register=True)
        self._arg_b = Operand.parse_operand(self, args[2], allow_literal=True, allow_register=True)


class NAND(BaseAlu):
    _MNEMONIC = 'nand'
    _OPCODE = 0

class OR(BaseAlu):
    _MNEMONIC = 'or'
    _OPCODE = 1

class AND(BaseAlu):
    _MNEMONIC = 'and'
    _OPCODE = 2

class NOR(BaseAlu):
    _MNEMONIC = 'nor'
    _OPCODE = 3

class ADD(BaseAlu):
    _MNEMONIC = 'add'
    _OPCODE = 5

class SUB(BaseAlu):
    _MNEMONIC = 'sub'
    _OPCODE = 6

class XOR(BaseAlu):
    _MNEMONIC = 'xor'
    _OPCODE = 7

class LSL(BaseAlu):
    _MNEMONIC = 'lsl'
    _OPCODE = 8

class LSR(BaseAlu):
    _MNEMONIC = 'lsr'
    _OPCODE = 9

class CMP(BaseAlu):
    _MNEMONIC = 'cmp'
    _OPCODE = 10

class MUL(BaseAlu):
    _MNEMONIC = 'mul'
    _OPCODE = 11

mnemonics = {
    NAND._MNEMONIC: NAND,
    OR._MNEMONIC: OR,
    AND._MNEMONIC: AND,
    NOR._MNEMONIC: NOR,
    ADD._MNEMONIC: ADD,
    SUB._MNEMONIC: SUB,
    XOR._MNEMONIC: XOR,
    LSL._MNEMONIC: LSL,
    LSR._MNEMONIC: LSR,
    CMP._MNEMONIC: CMP,
    MUL._MNEMONIC: MUL,
}