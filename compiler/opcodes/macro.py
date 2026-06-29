from compiler.objects import Inst
from .jmp import JMP
from compiler.directives.directives import Label

# bunch of random crap (multi) instruction shorthands
class Macro(Inst):
    def parse_args(self, args):
        raise NotImplementedError('Base macro not a macro')

class HLT(Macro):
    _MNEMONIC = 'hlt'
    def parse_args(self, args):
        return
    
    def build_multi_instruction(self):
        # while i could use relative labels
        # that might just cause more of a pain down the line
        labelname = f'halt_{self.line_nr}'
        label = Label(self.line_nr)
        label.parse_args([labelname])
        jmp = JMP(self.line_nr)
        jmp.parse_args([labelname])
        return [
            label,
            jmp
        ]


mnemonics= {
    HLT._MNEMONIC: HLT
}