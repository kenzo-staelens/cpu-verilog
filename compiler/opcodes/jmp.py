from objects.instruction import Inst, Operand

class BaseJMP(Inst):
    def __init__(self, *args):
        super().__init__(*args)
        self._mode = 2
        
    def parse_args(self, args):
        self.arg_a = Operand.parse_operand(self, 'flags', allow_register=True)
        self._arg_b = Operand.parse_operand(self, args[0],allow_literal=True, allow_word=True)
        

INVERT = 8
# = NEVER
class SSNOP(BaseJMP):
    _MNEMONIC = 'ssnop'
    _OPCODE = 0

class JMP(BaseJMP):
    _MNEMONIC = 'jmp'
    _OPCODE = 0 + INVERT

class JEQ(BaseJMP):
    _MNEMONIC = 'jeq'
    _OPCODE = 1

class JNE(BaseJMP):
    _MNEMONIC = 'jne'
    _OPCODE = 1 + INVERT

class JLT_U(BaseJMP):
    _MNEMONIC = 'jlt.u'
    _OPCODE = 2

class JGE_U(BaseJMP):
    _MNEMONIC = 'jge.u'
    _OPCODE = 2 + INVERT

class JLE_U(BaseJMP):
    _MNEMONIC = 'jle.u'
    _OPCODE = 3

class JGT_U(BaseJMP):
    _MNEMONIC = 'jgt.u'
    _OPCODE = 3 + INVERT

class JLT_S(BaseJMP):
    _MNEMONIC = 'jlt.s'
    _OPCODE = 4

class JGE_S(BaseJMP):
    _MNEMONIC = 'jge.s'
    _OPCODE = 4 + INVERT

class JLE_S(BaseJMP):
    _MNEMONIC = 'jle.s'
    _OPCODE = 5

class JGT_S(BaseJMP):
    _MNEMONIC = 'jgt.s'
    _OPCODE = 5 + INVERT

mnemonics = {
    SSNOP._MNEMONIC: SSNOP,
    JMP._MNEMONIC: JMP,
    JNE._MNEMONIC: JNE,
    JLT_U._MNEMONIC: JLT_U,
    JGE_U._MNEMONIC: JGE_U,
    JLE_U._MNEMONIC: JLE_U,
    JGT_U._MNEMONIC: JGT_U,
    JLT_S._MNEMONIC: JLT_S,
    JGE_S._MNEMONIC: JGE_S,
    JLE_S._MNEMONIC: JLE_S,
    JGT_S._MNEMONIC: JGT_S
}
