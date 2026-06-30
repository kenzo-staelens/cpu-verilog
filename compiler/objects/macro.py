from .directive import Directive


class UnresolvedMacro(Directive):
    _MNEMONIC = ''
    _NUM_ARGS = 1
    def __init__(self, line_nr, line_src):
        super().__init__(line_nr, line_src)
        self.name = '???'
    
    def _parse_args(self, args):
        self.name = args[0]
    
    def __str__(self):
        return f'{self.line_nr: >4d}: \x1b[31m%macro\x1b[0m \x1b[35m<Name: {self.name}>\x1b[0m'

    def __repr__(self):
        return f'<Macro Name={self.name}>'
    
    def copy(self):
        res = self.__class__(self.line_nr, self.line_src)
        res.name = self.name
        return res