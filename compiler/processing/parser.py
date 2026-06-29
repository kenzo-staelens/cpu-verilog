import sys
from compiler.errors import MissingOpcodeError, MissingDirectiveError, ParseError
from compiler.opcodes import OPCODES
from compiler.directives import DIRECTIVES
from compiler.objects import Inst, UnresolvedMacro

# note: directives are going to bbe a bitch to process

class Parser:
    def __init__(self, filename):
        self.filename = filename
        self.macros = {}

    def split_line(self, line):
        data = line.split(',')
        data = [*data[0].split(' ', 1), *data[1:]]
        data = [x.strip() for x in data]
        op, args = data[0], data[1:]
        return op, args

    # code duplication true but typing is going to be a pain
    def parse_directive(self, line, line_nr, line_src):
        mnemonic, args = self.split_line(line)
        if mnemonic not in DIRECTIVES:
            raise MissingDirectiveError(f'"{mnemonic}" does not exist')
        operation = DIRECTIVES[mnemonic](line_nr, line_src)
        operation.parse_args(args)
        return operation.build_multi_instruction()

    def parse_instruction(self, line, line_nr, line_src):
        mnemonic, args = self.split_line(line)
        if mnemonic not in OPCODES:
            raise MissingOpcodeError(f'"{mnemonic}" does not exist')
        operation: Inst = OPCODES[mnemonic](line_nr, line_src)
        operation.parse_args(args)
        return operation.build_multi_instruction()

    def parse_macro(self, line, line_nr, line_src):
        mnemonic, args = self.split_line(line)
        mnemonic = mnemonic[1:] # useful for later
        args = [mnemonic, *args]
        macro = UnresolvedMacro(line_nr, line_src)
        macro.parse_args(args)
        return macro.build_multi_instruction()

    def strip_comments(self, line):
        return line.split(';')[0].strip()

    def parse_file(self):
        parsed = []
        with open(self.filename, 'r') as f:
            for i, line in enumerate(f.readlines(), start=1):
                if not (line :=  self.strip_comments(line)):
                    continue
                line_src = f'{self.filename}:{i}'
                try:
                    if line.startswith('.'):
                        parsed += self.parse_directive(line, len(parsed), line_src)
                    elif line.startswith('%'):
                        parsed += self.parse_macro(line, len(parsed), line_src)
                    else:
                        parsed += self.parse_instruction(line, len(parsed), line_src)
                except ParseError as e:
                    print(f"error while parsing line \n{i:0>4d}: {line}")
                    print(str(e))
                    print(line_src)
                    sys.exit()
        return parsed
