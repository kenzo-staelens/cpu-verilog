from .line import Line


class Directive(Line):
    _ENCODABLE = False
    def __init__(self, line_nr, line_src):
        super().__init__(line_nr, line_src)

    def resolve(self, propose_address):
        # assumes a char fully fits
        self.address = propose_address
        return self.address

    def _parse_args(self, args):
        pass

    def copy(self):
        obj = self.__class__(self.line_nr, self.line_src)
        return obj