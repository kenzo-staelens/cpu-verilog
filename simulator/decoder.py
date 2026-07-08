from typing import NamedTuple

class Decoded(NamedTuple):
    mode: int
    immediate: int
    opcode: int
    dst: int
    arg_a: int
    arg_b: int 
    immediate_b: int

    def get_b(self):
        if self.immediate:
            return self.immediate_b
        return self.arg_b

    def set_a(self,value):
        return Decoded(self.mode, self.immediate, self.opcode, self.dst, value, self.arg_b, self.immediate_b)

    def set_b(self,value):
        return Decoded(self.mode, self.immediate, self.opcode, self.dst, self.arg_a, value, self.immediate_b)

class Decoder():
    def __init__(self):
        pass

    def decode(self, input: int) -> Decoded:
        mode = (input >>29)&0b11
        immediate = (input >>28)&0b1
        opcode = (input >>24)&0b1111
        dst= (input >>20)&0b1111
        arg_a = (input >>16)&0b1111
        arg_b = (input >>8)&0b1111
        immediate_b = input&0xFFFF
        return Decoded(
            mode=mode, 
            immediate=immediate, 
            opcode=opcode, 
            dst=dst, 
            arg_a=arg_a,
            arg_b=arg_b, 
            immediate_b=immediate_b
        )
        # return [mode, opcode, immediate, dst, arg_a, b_out]
        