import sys
from compiler.errors import MissingOpcodeError, MissingDirectiveError, ParseError
from compiler.opcodes import OPCODES
from compiler.directives import DIRECTIVES

# note: directives are going to bbe a bitch to process

class Parser:
    def __init__(self, filename):
        self.filename = filename

    def split_line(self, line):
        data = line.split(',')
        data = [*data[0].split(' ', 1), *data[1:]]
        data = [x.strip() for x in data]
        op, args = data[0], data[1:]
        return op, args

    def parse_line(self, line, line_nr, mnemonic_set, error_class):
        mnemonic, args = self.split_line(line)

        if mnemonic not in mnemonic_set:
            raise error_class(f'"{mnemonic}" does not exist')
        operation = mnemonic_set[mnemonic](line_nr)

        operation.parse_args(args)
        return operation.build_multi_instruction()

    def strip_comments(self, line):
        return line.split(';')[0].strip()

    def parse_file(self):
        parsed = []
        with open(self.filename, 'r') as f:
            for i, line in enumerate(f.readlines(), start=1):
                if not (line :=  self.strip_comments(line)):
                    continue
                try:
                    if line.startswith('.'):
                        mnemonic_set = DIRECTIVES
                        error_class = MissingDirectiveError
                    else:
                        mnemonic_set = OPCODES
                        error_class = MissingOpcodeError
                    parsed += self.parse_line(line, i, mnemonic_set, error_class)
                except ParseError as e:
                    print(f"error while parsing line\n{i:0>4d}: {line}")
                    print(str(e))
                    sys.exit()
        return parsed
