from compiler.objects import Directive, Operand
from math import ceil

class Raw(Directive):
    _MNEMONIC = 'raw'
    _NUM_ARGS = 1
    _ENCODABLE = 1

    def _parse_args(self, args):
        # passing through operand for validation, not so much storage
        op = Operand.parse_operand(self, args[0], allow_literal=True)
        self._raw_data = op.value
        self._SIZE = ceil(op.raw_size/2)
        # literal off-alignment bytes not supported due to cannot compute instruction address

    def __str__(self):
        return f'{self.line_nr: >4d}: \x1b[31m{self._MNEMONIC}\x1b[0m \x1b[35m<data: {self._raw_data:x}>\x1b[0m'

    def __repr__(self):
        return f'<raw data={self._raw_data:_x}>'

    def copy(self):
        obj = super().copy()
        obj._raw_data = self._raw_data
        obj._SIZE = self._SIZE
        return obj
    
    def encode(self):
        self.encoded = self._raw_data

class Text(Directive):
    _MNEMONIC = 'text'
    _NUM_ARGS = 1
    _ENCODABLE = 1

    def _parse_args(self, args):
        # TODO: passing through operand for validation, not so much storage
        # self._raw_data = Operand.parse_operand(self, args[0], allow_literal=True).value
        self._raw_data: str = Operand.parse_operand(self, args[0], allow_string=True).value
        self._SIZE = len(self._raw_data)

    def __str__(self):
        return f'{self.line_nr: >4d}: \x1b[31m{self._MNEMONIC}\x1b[0m \x1b[35m<data: "{self._raw_data}">\x1b[0m'

    def __repr__(self):
        return f'<raw data="{self._raw_data}">'

    def copy(self):
        obj = super().copy()
        obj._raw_data = self._raw_data
        obj._SIZE = self._SIZE
        return obj
    
    def encode(self):
        encoded = 0
        for char in self._raw_data:
            encoded <<= 16
            encoded += ord(char)
        self.encoded = encoded
