from compiler.objects import Line
import sys

class BaseProcessor():
    def __init__(self, instructions, error_msg = "generic error"):
        self.instructions: list[Line] = instructions
        self.error_message = error_msg

    def fix_line_nr(self):
        reordered = []
        for i, inst in enumerate(self.instructions):
            new_inst = inst.copy()
            new_inst.line_nr = i
            reordered.append(new_inst)
        self.instructions = reordered

    def _process(self):
        raise NotImplementedError('BaseProcessor._process is not implemented')

    def process(self):
        try:
            return self._process()
        except Exception as e:
            print('\x1b[31m\x1b[1m' + self.error_message + '\x1b[0m')
            print(str(e))
            print()
            sys.exit()