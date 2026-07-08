class ALU:
    def __init__(self):
        pass

    def run_op(self, opcode, arg_a_in, arg_b_in):
        mask = (2**16-1)
        arg_a = arg_a_in & mask
        arg_b = arg_b_in & mask
        a_signed = self.unsigned_to_signed(arg_a, 16)
        b_signed = self.unsigned_to_signed(arg_b, 16)
        eq = arg_a_in == arg_b_in
        u_less = arg_a < arg_b
        s_less = a_signed < b_signed
        cmp = (s_less<<2) + (u_less<<1) + eq

        match opcode:
            case 0:
                res =  ~(arg_a & arg_b)
            case 1:
                res =  arg_a | arg_b
            case 2:
                res =  arg_a & arg_b
            case 3:
                res =  ~(arg_a | arg_b)
            case 4:
                res =  arg_a + arg_b
            case 5:
                res =  arg_a - arg_b
            case 6:
                res =  arg_a ^ arg_b
            case 7:
                res =  arg_a << arg_b
            case 8:
                res =  arg_a >> arg_b
            case 9:
                print('cmp', arg_a, arg_b)
                res =  cmp
            case 10:
                res = (arg_a&255)*(arg_b&255)
            case _:
                res = 0
        return res & mask
        
    @classmethod
    def unsigned_to_signed(cls, val, bits):
        # alu is the only thing that understands
        # negative values, just handle them here
        mask = 1 << (bits - 1)      # e.g. 0x80 for 8 bits
        if val & mask:
            return val - (1 << bits)
        return val