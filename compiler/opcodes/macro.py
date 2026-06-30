from compiler.objects import Inst
from .jmp import JMP
from compiler.directives.directives import Label
from compiler.opcodes.alu import ADD

# fully internal (not %macro definitions) but ones that don't
# 1:1 map to an opcode in the ISA
# bunch of random crap (multi) instruction shorthands
class Macro(Inst):
    def _parse_args(self, args):
        raise NotImplementedError('Base macro not a macro')

class HLT(Macro):
    _MNEMONIC = 'hlt'
    def _parse_args(self, args):
        return
    
    def build_multi_instruction(self):
        # while i could use relative labels
        # that might just cause more of a pain down the line
        labelname = f'halt_{self.line_nr}'
        label = Label(self.line_nr, self.line_src)
        label.parse_args([labelname])
        jmp = JMP(self.line_nr + 1, self.line_src)
        jmp.parse_args([labelname])
        return [
            label,
            jmp
        ]

class MOV(Macro):
    _NUM_ARGS = 2
    _MNEMONIC = 'mov'
    def _parse_args(self, args):
        # patch in constant zr as argb
        self._tmp_args = args
        
    def build_multi_instruction(self):
        res = ADD(self.line_nr, self.line_src)
        # inputs dst, argb
        res.parse_args([self._tmp_args[0], 'zr', self._tmp_args[1]])
        return res.build_multi_instruction()

mnemonics= {
    HLT._MNEMONIC: HLT,
    MOV._MNEMONIC: MOV
}