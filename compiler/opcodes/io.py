from compiler.objects import Inst, Operand

class IOBase(Inst):
    _DIRECTION = 'out'
    _NUM_ARGS = 1
    def __init__(self, *args):
        super().__init__(*args)
        self._mode = 0
    
    def _parse_args(self, args):
        if self._DIRECTION == 'in':
            self._dst = Operand.parse_operand(self,args[0], allow_register=True)
        if self._DIRECTION == 'out':
            # self._arg_b = Operand.parse_operand(self, args[0], allow_register=True, allow_literal=True)
            self._arg_b = Operand.parse_operand(self, args[0], allow_register=True, allow_literal=True)

class NOP(IOBase):
    _MNEMONIC = 'nop'
    _OPCODE = 0
    _NUM_ARGS = 0

    def _parse_args(self, args):
        pass

class CLK(IOBase):
    _MNEMONIC = 'clk'
    _OPCODE = 1
    _DIRECTION = 'in'

class IN(IOBase):
    _MNEMONIC = 'in'
    _OPCODE = 2
    _DIRECTION = 'in'

class OUT(IOBase):
    _MNEMONIC = 'out'
    _OPCODE = 3

class STS(IOBase):
    _MNEMONIC = 'sts'
    _OPCODE = 4
    _DIRECTION = 'in'
    

class DEV(IOBase):
    _MNEMONIC = 'dev'
    _OPCODE = 5

mnemonics = {
    NOP._MNEMONIC: NOP,
    CLK._MNEMONIC: CLK,
    IN._MNEMONIC: IN,
    OUT._MNEMONIC: OUT,
    STS._MNEMONIC: STS,
    DEV._MNEMONIC: DEV,
}



