from .line import Line


class Directive(Line):
    _ENCODABLE = False
    def __init__(self, line_nr, line_src):
        super().__init__(line_nr, line_src)

    def resolve(self, propose_address):
        self.address = propose_address
        return self.address

    def parse_args(self, args):
        pass