from compiler.objects import Directive

class Label(Directive):
    _MNEMONIC = 'label'
    _NUM_ARGS = 1
    def __init__(self, line_nr, line_src):
        super().__init__(line_nr, line_src)
        self._labelname = '???'

    def _parse_args(self, args):
        self._labelname = args[0]

    def __str__(self):
        return f'{self.line_nr: >4d}: \x1b[31m{self._MNEMONIC}\x1b[0m \x1b[35m<Name: {self._labelname}>\x1b[0m'

    def __repr__(self):
        return f'<Label Name={self._labelname}>'

    def copy(self):
        obj = super().copy()
        obj._labelname = self._labelname
        return obj