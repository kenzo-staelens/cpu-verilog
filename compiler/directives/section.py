from compiler.objects import Directive

class Section(Directive):
    _MNEMONIC = "section"
    _NUM_ARGS = 1
    _ALLOW_SECTIONS  = ['.text', '.bss', '.data', '.vector']

    def __init__(self, line_nr, line_src):
        super().__init__(line_nr, line_src)
        self.name = '???'

    def _parse_args(self, args):
        self.name = args[0]
        if self.name not in self._ALLOW_SECTIONS:
            raise SyntaxError(f'Invalid Section {args[0]}')

    def __str__(self):
        return f'{self.line_nr: >4d}: \x1b[31m{self._MNEMONIC}\x1b[0m \x1b[35m<Name: {self.name}>\x1b[0m'

    def __repr__(self):
        return f'<Section Name={self.name}>'

    # resolving is kind of messy -> better to resolve this one in the resolver class

    def copy(self):
        obj = super().copy()
        obj.name = self.name
        return obj
