# base class for directives and instructions

class Line:
    _MNEMONIC = '???'
    _ENCODABLE = True
    def __init__(self, line_nr, line_src):
        self.line_nr = line_nr
        self.address = 0
        self.encoded: int | None = None
        self.line_src: str = line_src

    def build_multi_instruction(self):
        # default just one instructions
        # some cases may make more complex things 
        # like call and ret
        return [self]