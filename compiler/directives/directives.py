from compiler.objects import Directive, Operand

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

class Org(Directive):
    _MNEMONIC = 'org'
    _NUM_ARGS = 1

    def _parse_args(self, args):
        self._align_to = Operand.parse_operand(self, args[0], allow_literal=True)
        self._phantom = False
        self._gen_from: str | None = None

    def __str__(self):
        return f'{self.line_nr: >4d}: \x1b[31m{self._MNEMONIC}\x1b[0m \x1b[35m<start: {self._align_to.value}>\x1b[0m \x1b[35m<Phantom: {int(self._phantom)}>\x1b[0m \x1b[90m<From {self._gen_from}>\x1b[0m'

    def __repr__(self):
        return f'<Org Name={self._align_to}>'
    
    def resolve(self, propose_address):
        # phantom sections are, for example, the first section of a section without org
        # they're allowed to just shift to the current address (tail of the binary)
        # otherwise take an absolute! address
        if self._phantom:
            self._align_to.value = propose_address
        if propose_address > self._align_to.value:
            raise RuntimeError(f'Attempted to align to {self._align_to.value} while at {propose_address}')
        self.address = self._align_to
        return self._align_to.value

    def copy(self):
        obj = super().copy()
        obj._align_to = self._align_to
        obj._phantom = self._phantom
        obj._gen_from = self._gen_from 
        return obj

class Align(Directive):
    _MNEMONIC = 'align'
    _NUM_ARGS = 1

    def _parse_args(self, args):
        self._align_to = Operand.parse_operand(self, args[0], allow_literal=True)

    def __str__(self):
        return f'{self.line_nr: >4d}: \x1b[31m{self._MNEMONIC}\x1b[0m \x1b[35m<start: {self._align_to.value}>\x1b[0m'

    def __repr__(self):
        return f'<Org Name={self._align_to}>'
    
    def resolve(self, propose_address):
        # difference in alignment or 0 if aligned
        align_to = self._align_to.value
        diff = (align_to - (propose_address % align_to)) % align_to
        self.address = propose_address + diff
        return self.address

    def copy(self):
        obj = super().copy()
        obj._align_to = self._align_to
        return obj

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

# todo
# RAW type directives

# leading dot
NORMAL_DIRECTIVES: list[type[Directive]] = [
    Label,
    Macro,
    Endmacro,
    Org,
    Align,
]
# no leading dot
ABNORMAL_DIRECTIVES: list[type[Directive]] = [
    Section
]
directives: dict[str, type[Directive]] = {
    **{  # kinda cursed
        '.' + c._MNEMONIC: c
        for c in NORMAL_DIRECTIVES
    },
    **{  # kinda cursed
        c._MNEMONIC: c
        for c in ABNORMAL_DIRECTIVES
    }
}
