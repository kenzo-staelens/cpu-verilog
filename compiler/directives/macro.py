from compiler.objects import Directive


class Macro(Directive):
    _MNEMONIC = 'macro'
    _NUM_ARGS = 1

    def __init__(self, line_nr, line_src):
        super().__init__(line_nr, line_src)
        self.name = '???'

    def _parse_args(self, args):
        self.name = args[0]

    def __str__(self):
        return f'{self.line_nr: >4d}: \x1b[31m{self._MNEMONIC}\x1b[0m \x1b[35m<Name: {self.name}>\x1b[0m'

    def __repr__(self):
        return f'<Macrodef Name={self.name}>'

    def copy(self):
        obj = super().copy()
        obj.name = self.name
        return obj

class Endmacro(Directive):
    _MNEMONIC = 'endmacro'

    def __str__(self):
        return f'{self.line_nr: >4d}: \x1b[31m{self._MNEMONIC}\x1b[0m'

    def __repr__(self):
        return '<endmacro>'