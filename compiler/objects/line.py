from typing import Self
# base class for directives and instructions

class Line:
    _MNEMONIC: str = '???'
    _ENCODABLE = True
    _NUM_ARGS = 0
    _SIZE = 0
    def __init__(self, line_nr, line_src):
        self.line_nr = line_nr
        self.address = 0
        self.encoded: int | None = None
        self.line_src: str = line_src

    def parse_args(self, args):
        if self._NUM_ARGS is not None and len(args) != self._NUM_ARGS:
            raise SyntaxError(f'expected {self._NUM_ARGS} but got {len(args)}')
        self._parse_args(args)

    def _parse_args(self, args):
        pass

    def build_multi_instruction(self):
        # default just one instructions
        # some cases may make more complex things 
        # like call and ret
        return [self]

    def copy(self) -> Self:
        raise NotImplementedError(f'Copy not implemented on instance of {self._MNEMONIC}')
    
    def encode(self):
        raise NotImplementedError(f'Encode not implemented on instance of {self._MNEMONIC}')