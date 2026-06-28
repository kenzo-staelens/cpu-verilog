from objects import Inst, Directive, Operand 
from directives.directives import Label
from errors import ResolverError

class Resolver:
    def __init__(self, instructions, inst_width = 2):
        self.current_address = 0
        self.inst_width = inst_width
        self.labels = {}
        self.instructions = instructions
    
    def resolve_directive(self, directive: Directive):
        self.current_address = directive.resolve(self.current_address)
        if isinstance(directive, Label):
            if directive._labelname in self.labels:
                raise ResolverError(f'label {directive._labelname} already defined on address {directive.line_nr}')
            self.labels[directive._labelname] = self.current_address

    def resolve_instruction(self, inst: Inst):
        if inst._arg_b.literal:
            inst._immediate = True
        if not inst._arg_b.resolved:
            inst._arg_b.resolve()
            if inst._mode == 2:  # jmp
                self.resolve_label(inst._arg_b)
        self.current_address += self.inst_width

    def resolve_label(self, arg_b: Operand):
        arg_b._address = True
        arg_b.value = self.labels[arg_b.unresolved_value]

    def resolve_addresses(self):
        for inst in self.instructions:
            if isinstance(inst, Directive):
                self.resolve_directive(inst)
            elif isinstance(inst, Inst):
                self.resolve_instruction(inst)
            else:
                raise NotImplementedError(f'Instruction Type (type{inst}) not implemented')
