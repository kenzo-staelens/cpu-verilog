import re
from .line import Line
from compiler.errors import (
    OperandError,
    MissingRegisterError,
    InvalidLiteralError,
    DataSizeError,
)

from math import ceil

class Operand:
    _MAX_LITERAL_ENCODING_SIZE = 16

    def __init__(self, inst: Line, value:int|str=0, literal:bool=True, resolved:bool=True, used=True):
        self.unresolved_value = value
        self.value = value
        self.literal = literal
        self.resolved = resolved
        self._address = False  # to be set by resolver
        self._used = used
        self.instruction = inst
        self.raw_size = None  # only used for a couple directives

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
    def _check_encoding_size(cls, literal, rawsize):
        if rawsize*8 > cls._MAX_LITERAL_ENCODING_SIZE:
            message = (
                f'attempted to apply {literal} '
                f'in {cls._MAX_LITERAL_ENCODING_SIZE} bits but not enough space is available.\n'
                'please separate larger data by commas'
            )
            raise DataSizeError(message)

    @classmethod
    def _remap_octal(cls, value):
        map_data = {
            '0': '000',
            '1': '001',
            '2': '010',
            '3': '011',
            '4': '100',
            '5': '101',
            '6': '110',
            '7': '111',
        }
        mapped = ''
        for char in value:
            mapped += map_data[char]
        
        if value[0] != '0':
            mapped = mapped.lstrip('0')
        print(mapped)
        return mapped

    @classmethod
    def parse_literal(cls, inst: Line, operand: str):
        try:
            if operand.startswith('0x'):
                v = int(operand[2:], 16)
                b = ceil(len(operand[2:])*4/8)
            elif operand.startswith('0b'):
                v = int(operand[2:], 2)
                b = ceil(len(operand[2:])/8)
            elif operand.startswith('0o'):
                v = int(operand, 8)
                b =ceil(len(cls._remap_octal(operand[2:]))/8)
                # b = ceil(len(operand[2:])*3/8)
            else:
                v= int(operand)
                temp = v
                b = 0
                while temp>0:
                    b+=1
                    temp >>= 8
            op = Operand(inst, v, True)
            op.raw_size = b
            cls._check_encoding_size(operand, b)
            return op
        except ValueError:
            raise InvalidLiteralError(f'invalid literal {operand}')

    @classmethod
    def parse_address(cls, inst: Line, operand: str):
        return Operand(inst, 0, True)

    @classmethod
    def parse_char(self, inst: Line, operand: str):
        if not operand.endswith("'") or len(operand) != 3:
            raise InvalidLiteralError(f'Invalid char declaration {operand}')
        return Operand(inst, ord(operand[1]), True)

    @classmethod
    def parse_word(cls, inst, operand: str):
        return Operand(inst,operand, True, False)

    @classmethod
    def parse_string(cls, inst, operand: str):
        # needs start and end "", also cannot have " within body
        if not operand.endswith('"') or '"' in operand[1:-1]:
            raise InvalidLiteralError(f'Invalid string declaration {operand}')
        return Operand(inst, operand, literal=True)

    @classmethod
    def _valid_literal(self, operand):
        return (
            re.match(r'\b\d+\b',operand)
        or re.match('0b[01]+',operand, re.IGNORECASE)
        or re.match('0o[0-7]+',operand,re.IGNORECASE)
        or re.match('0x[0-9a-f]+',operand, re.IGNORECASE)
        )
    
    @classmethod
    def parse_operand(
        cls,
        inst,
        operand: str,
        allow_register: bool = False,
        allow_literal: bool = False,
        allow_string: bool = False,
        allow_address: bool = False,
        allow_word: bool = False,
        literal_max: int | None = None
    ):
        if literal_max and isinstance(literal_max, int) and literal_max>0:
            cls._MAX_LITERAL_ENCODING_SIZE = literal_max
        
        if allow_register and (
            re.match(r'r\d+',operand, )
            or operand in {'zr', 'flags', 'sp'}
        ):
            return cls.parse_register(inst, operand)
        if allow_literal and operand.startswith("'"):
            return cls.parse_char(inst, operand)
        if allow_string and operand.startswith('"'):
            return cls.parse_string(inst, operand)
        if allow_literal and cls._valid_literal(operand):
            return cls.parse_literal(inst, operand)
        if allow_address and operand.startswith('='):
            return cls.parse_address(inst, operand)
        if allow_word:
            return cls.parse_word(inst, operand)
        expect_flags = (
            allow_register,
            allow_literal,
            allow_string,
            allow_address,
            allow_word,
        )
        expects = '\n'.join([
            x for i,x in enumerate(['register', 'literal', 'string', 'address', 'word'])
            if expect_flags[i]
        ])
        raise OperandError(f'Unexpected operand {operand}, expected one of\n{expects}')
