from .line import Line

class Directive(Line):
    _ENCODABLE = False
    def __init__(self, line_nr):
        super().__init__(line_nr)

    def resolve(self, propose_address):
        self.address = propose_address
        return self.address
