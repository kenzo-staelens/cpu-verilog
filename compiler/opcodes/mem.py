from compiler.objects import Inst, Operand

class BaseMEM(Inst):
    _NUM_ARGS = 2
    _OP = 0
    def __init__(self, *args):
        super().__init__(*args)
        self._mode = 3

    def _parse_args(self, args):
        self._dst = Operand.parse_operand(self, args[0], allow_register=True)
        self._arg_b = Operand.parse_operand(self, args[1], allow_literal=True, allow_register=True)

class MEMLD(BaseMEM):
    _OP = 0
    def _parse_args(self, args):
        self._dst = Operand.parse_operand(self, args[0], allow_register=True)
        self._arg_b = Operand.parse_operand(self, args[1], allow_literal=True, allow_register=True)
    
class MEMSTR(BaseMEM):
    _OP = 1
    def _parse_args(self, args):
        self._arg_a = Operand.parse_operand(self, args[0], allow_register=True)
        self._arg_b = Operand.parse_operand(self, args[1], allow_literal=True, allow_register=True)
    
def construct_mem_opcode(name, mnemonic, base: type[BaseMEM], dev):
    opcode = (dev << 2) + base._OP
    return type(name, (base,), {'_MNEMONIC': mnemonic, '_OPCODE': opcode})

LD16: type[BaseMEM] = construct_mem_opcode('LD16', 'ld', MEMLD, 0)
STR16: type[BaseMEM] = construct_mem_opcode('STR16', 'str', MEMSTR, 0)
LD16P: type[BaseMEM] = construct_mem_opcode('LD16P', 'ld.p', MEMLD, 1)
STR16P: type[BaseMEM] = construct_mem_opcode('STR16P', 'str.p', MEMSTR, 1)

mnemonics = {
    LD16._MNEMONIC: LD16,
    STR16._MNEMONIC: STR16,
    LD16P._MNEMONIC: LD16P,
    STR16P._MNEMONIC: STR16P
}