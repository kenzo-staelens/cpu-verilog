from compiler.objects import Directive, Operand

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