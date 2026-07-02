from compiler.objects import Inst, UnresolvedMacro, Line
from compiler.directives.directives import Macro, Endmacro
from compiler.errors import ResolverError
from .base_processor import BaseProcessor
from typing import cast

class MacroPreprocessor(BaseProcessor):
    def __init__(self, instructions, error_msg = "error while resolving macros"):
        super().__init__(instructions, error_msg)
        self.macros = {}
        self.building_macro = None

    
    def register_macros(self):
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
                    original = cast('list[Line]', self.macros[inst.name])
                    resolved_instructions += original
                    has_unresolved = True
                    continue
                resolved_instructions.append(cast(Inst, inst))
            self.instructions = resolved_instructions
            resolved_instructions = []
        # fix shifted indexing
        self.fix_line_nr()

    def _process(self):
        self.register_macros()
        self.resolve_macros()
        return self.instructions