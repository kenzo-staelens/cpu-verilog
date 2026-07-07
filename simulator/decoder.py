class Decoder():
    def __init__(self):
        pass

    def decode(self, input: int) -> list[int]:
        mode = (input >>29)&0b11
        immediate = (input >>28)&0b1
        opcode = (input >>24)&0b1111
        dst= (input >>20)&0b1111
        arg_a = (input >>16)&0b1111
        arg_b = (input >>8)&0b1111
        immediate_b = input&0xFFFF
        b_out = immediate_b if immediate else arg_b 
        return [mode, opcode, immediate, dst, arg_a, b_out]
        