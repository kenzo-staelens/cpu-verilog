from .line import Line
from .operand import Operand

class Inst(Line):
    _OPCODE = 0
    def __init__(self, line_nr, line_src):
        super().__init__(line_nr, line_src)
        self._opcode = self._OPCODE
        self._mode = 0
        self._immediate = 0
        self._dst: Operand = Operand(self, used=False)
        self._arg_a: Operand = Operand(self, used=False)
        self._arg_b: Operand = Operand(self, used=False)

    def copy(self):
        res = self.__class__(self.line_nr, self.line_src)
        res._mode = self._mode
        res._immediate = self._immediate
        res._dst = self._dst.copy(res)
        res._arg_a = self._arg_a.copy(res)
        res._arg_b = self._arg_b.copy(res)
        return res

    def __repr__(self):
        x = (
            f'<\x1b[36m{self._MNEMONIC}\x1b[0m'
            f'\n\t\x1b[35mOpcode = {self._opcode}\x1b[0m'
            f'\n\t\x1b[33mMode = {self._mode}\x1b[0m'
            f'\n\t\x1b[35mImmediate = {self._immediate}\x1b[0m'
            f'\n\tdst = {repr(self._dst)}'
            f'\n\targ a = {repr(self._arg_a)}'
            f'\n\targ b = {repr(self._arg_b)}'
            '\n>'
        )
        return x

    def __str__(self):
        ops: list[tuple[str, Operand]] = []
        if self._dst._used:
            ops.append(('dst', self._dst))
        if self._arg_a._used:
            ops.append(('arg_a', self._arg_a))
        if self._arg_b._used:
            ops.append(('arg_b' ,self._arg_b))
        ops_str: str = ' '.join(f'{x[0]}={x[1]}' for x in ops)
        return f'{self.line_nr: >4d}: \x1b[36m{self._MNEMONIC}\x1b[0m \x1b[33m<Mode: {self._mode}>\x1b[0m \x1b[35m<Immediate: {int(self._immediate)}>\x1b[0m {ops_str}'

    def _parse_args(self, args):
        pass