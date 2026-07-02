from compiler.objects import Inst, Directive
from compiler.directives.directives import Label
from compiler.errors import ResolverError
from .base_processor import BaseProcessor
import re
from typing import cast

# may also generate a symbol table in the future
class Resolver(BaseProcessor):
    def __init__(self, instructions, max_addresses, inst_width = 2, error_msg = "error while resolving addresses"):
        super().__init__(instructions, error_msg)
        self.current_address = 0
        self.inst_width = inst_width
        self.labels = {}
        self.max_addresses = max_addresses
    
    def resolve_directive(self, directive: Directive):
        self.current_address = directive.resolve(self.current_address)
        if self.current_address > self.max_addresses:
            raise RuntimeError(f'Failed to resolve all instructions within {self.max_addresses} addresses')
        if isinstance(directive, Label):
            if directive._labelname.isnumeric():
                if directive._labelname not in self.labels:
                    self.labels[directive._labelname] = []
                self.labels[directive._labelname].append((directive.line_nr, self.current_address))
                return
            
            if directive._labelname in self.labels:
                raise ResolverError(f'label {directive._labelname} already defined on address {directive.line_nr}\n{directive.line_src}')
            else:
                self.labels[directive._labelname] = self.current_address

    def resolve_instruction(self, inst: Inst):
        if inst._arg_b.literal:
            inst._immediate = True
        if not inst._arg_b.resolved:
            inst._arg_b.resolve()
        inst.address = self.current_address
        self.current_address += self.inst_width

    def resolve_label(self, line_nr, inst: Inst):
        arg_b = inst._arg_b
        arg_b._address = True
        if isinstance(arg_b.value, int):
            return  # hardcoded address
        if arg_b.unresolved_value not in self.labels and not re.match(
            r'\d+(b|f)',
            cast(str, arg_b.unresolved_value),
        ):
            raise ResolverError(f'Failed to resolve label {arg_b.unresolved_value}\n{inst.line_src}')
        label_address = self.labels.get(arg_b.unresolved_value)
        if isinstance(label_address, int):
            arg_b.value = label_address
            return
        if match := re.match(r'(\d+)(b|f)', cast(str, arg_b.unresolved_value)):
            labelname = match.group(1)
            direction = match.group(2)
            
            def predicate(label_line):
                if direction == 'b':
                    return label_line < line_nr
                if direction == 'f':
                    return label_line > line_nr
                raise ResolverError(f'Failed to resolve label {arg_b.unresolved_value}\n{inst.line_src}')
            
            label_addresses = self.labels[labelname]
            label_address = None
            for l_line, l_addr in label_addresses:
                if not predicate(l_line):
                    continue
                if label_address is None:
                    label_address = l_addr
                    continue
                
                if abs(label_address - l_line) < abs(label_address-line_nr):
                    label_address = l_addr
            
            if label_address is not None:
                arg_b.value = label_address
                return

        raise ResolverError(f'Failed to resolve label {arg_b.unresolved_value}\n{inst.line_src}')
        
    def register_addresses(self):
        # resolve what able, save the rest as forward references
        for inst in self.instructions:
            if isinstance(inst, Directive):
                self.resolve_directive(inst)
            if isinstance(inst, Inst):
                self.resolve_instruction(inst)
            if not isinstance(inst, (Directive, Inst)):
                raise NotImplementedError(f'Instruction Type (type{inst}) not implemented\n{inst.line_src}')
    
    def resolve_addresses(self):
        for inst in self.instructions:
            # process forward references
            if isinstance(inst, Inst) and inst._mode == 2:  # jmp
                self.resolve_label(inst.line_nr, inst)
    
    def _process(self):
        self.register_addresses()
        self.resolve_addresses()
        return self.instructions