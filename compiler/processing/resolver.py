from compiler.objects import Inst, Directive, UnresolvedMacro, Line
from compiler.directives.directives import Label, Macro, Endmacro
from compiler.errors import ResolverError
import re
from typing import cast
import sys

class Resolver:
    def __init__(self, instructions, inst_width = 2):
        self.current_address = 0
        self.inst_width = inst_width
        self.labels = {}
        self.macros = {}
        self.instructions = instructions
        self.building_macro = None
    
    def resolve_directive(self, directive: Directive):
        self.current_address = directive.resolve(self.current_address)
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
        self.current_address += self.inst_width

    def resolve_label(self, line_nr, inst: Inst):
        arg_b = inst._arg_b
        arg_b._address = True
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
        
    def register_macros(self):
        # 
        for iln, inst in enumerate(self.instructions):
            if isinstance(inst, Macro):
                if self.building_macro:
                    raise SyntaxError(f'Cannot define macro while inside another macro\n{inst.line_src}')
                self.building_macro = inst.name
                if inst.name in self.macros:
                    raise ResolverError(f'macro {inst.name} already defined on address {inst.line_nr}\n{inst.line_src}')
            if isinstance(inst, Endmacro):
                i = iln-1
                captured_instructions = []
                while not isinstance(self.instructions[i], Macro):
                    captured_instructions.insert(0, self.instructions[i])
                    i-=1
                self.macros[self.building_macro] = captured_instructions
                self.building_macro = None
        if self.building_macro:
            raise SyntaxError(f'Unterminated macro {self.building_macro}\n{inst.line_src}')
    
    def resolve_macros(self):
        has_unresolved = True
        resolved_instructions: 'list[Line]' = []
        dropping_instructions = False
        while has_unresolved:
            has_unresolved = False
            for inst in self.instructions:
                if isinstance(inst, Endmacro):
                    dropping_instructions = False
                    continue
                if isinstance(inst, Macro):
                    dropping_instructions = True
                if dropping_instructions:
                    continue
                if isinstance(inst, UnresolvedMacro):
                    if inst.name not in self.macros:
                        raise ResolverError(f'Macro {inst.name} not found\n{inst.line_src}')
                    resolved_instructions += cast('list[Line]', self.macros[inst.name])
                    has_unresolved = True
                    continue
                resolved_instructions.append(cast(Inst, inst))
            self.instructions = resolved_instructions
            resolved_instructions = []
        # fix shifted indexing
        for i, inst in enumerate(self.instructions):
            inst.line_nr = i


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
    
    def resolve(self):
        try:
            self.register_macros()
            self.resolve_macros()
        except (ResolverError, SyntaxError) as e:
            print("error while resolving macro")
            print(str(e))
            sys.exit()
        try:
            self.register_addresses()
            self.resolve_addresses()
        except (ResolverError, NotImplementedError, SyntaxError) as e:
            print("error while resolving addresses")
            print(str(e))
            sys.exit()
        return self.instructions