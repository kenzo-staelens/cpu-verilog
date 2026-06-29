import re
from .line import Line
from compiler.errors import OperandError, MissingRegisterError, InvalidLiteralError

class Operand:
    def __init__(self, inst: Line, value:int|str=0, literal:bool=True, resolved:bool=True, used=True):
        self.unresolved_value = value
        self.value = value
        self.literal = literal
        self.resolved = resolved
        self._address = False  # to be set by resolver
        self._used = used
        self.instruction = inst

    def copy(self, inst):
        obj = Operand(inst, self.unresolved_value, self.literal, self.resolved, self._used)
        obj._address = self._address
        self.value = self.value
        return obj

    def resolve(self):
        self.resolved = True

    def __str__(self):
        if not self._used:
            return ''
        # yellow
        if not self._address and not self.literal and self.resolved:
            return f'\x1b[33m<REG: {self.value}>\x1b[0m'
        if not self._address and self.literal and self.resolved:
            if self.literal:
                return f'\x1b[32m<VALUE: 0x{self.value:0>4x}>\x1b[0m'
            else:
                return f'\x1b[32m<VALUE: 0x{self.value:0>16x}>\x1b[0m'
        if self._address:
            return f'\x1b[35m<ADDRESS: {self.unresolved_value} ({self.value:0>16x})>\x1b[0m'
        if not self.resolved:
            return f'\x1b[35m<ADDRESS: {self.value}>\x1b[0m'

        return f'\x1b[31m<???: {self.value}>\x1b[0m'

    def __repr__(self):
        colorcode = '\x1b[94m' # "bright blue"
        if not self._used:
            colorcode = '\x1b[90m'
        elif not self._address and self.literal and self.resolved:
            colorcode = '\x1b[32m' # green
        elif not self._address and self.literal and not self.resolved:
            colorcode = '\x1b[31m' # red
        elif self._address and not self.resolved:
            colorcode = '\x1b[35m' # bright magenta
        elif self._address and self.resolved:
            colorcode = '\x1b[95m' # bright magenta

        return f'{colorcode}<Unresolved={self.unresolved_value} Value={self.value}, Literal={int(self.literal)}, Resolved={int(self.resolved)} Address={int(self._address)} Used={int(self._used)}>\x1b[0m'

    @classmethod
    def parse_register(cls, inst: Line, operand: str):
        try:
            if operand == 'zr':
                v =  0
            elif operand == 'flags':
                v =  14
            elif operand == 'sp':
                v =  15
            else:
                v = int(operand[1:])
            return Operand(inst, v, False)
        except ValueError:
            raise MissingRegisterError(f'invalid register {operand}')

    @classmethod
    def parse_literal(cls, inst: Line, operand: str):
        try:
            if operand.startswith('0x'):
                v = int(operand[2:], 16)
            elif operand.startswith('0b'):
                v = int(operand[2:], 2)
            elif operand.startswith('0o'):
                v = int(operand, 8)
            else:
                v= int(operand)
            return Operand(inst, v, True)
        except ValueError:
            raise InvalidLiteralError(f'invalid literal {operand}')

    @classmethod
    def parse_address(cls, inst: Line, operand: str):
        return Operand(inst, 0, True)

    @classmethod
    def parse_word(cls, inst, operand: str):
        return Operand(inst,operand, True, False)

    
    @classmethod
    def parse_operand(
        self,
        inst,
        operand: str,
        allow_register: bool = False,
        allow_literal: bool = False,
        allow_address: bool = False,
        allow_word: bool = False
    ):
        if allow_register and (
            re.match(r'r\d+',operand, )
            or operand in {'zr', 'flags', 'sp'}
        ):
            return self.parse_register(inst, operand)
        if allow_literal and re.match(r'(0(o|x|b))?\d+$',operand):
            return self.parse_literal(inst, operand)
        if allow_address and operand.startswith('='):
            return self.parse_address(inst, operand)
        if allow_word:
            return self.parse_word(inst, operand)
        expect_flags = (allow_register, allow_literal, allow_address, allow_word)
        expects = '\n'.join([
            x for i,x in enumerate(['register', 'literal', 'address', 'word'])
            if expect_flags[i]
        ])
        raise OperandError(f'Unexpected operand {operand}, expected one of\n{expects}')
