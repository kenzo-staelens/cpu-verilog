class Clock:
    def __init__(self):
        self.pc = 0
        self.step_size = 2

    def step(self, bus, jmp):
        if jmp:
            self.pc = bus
            return self.pc
        self.pc += self.step_size

    def compute_hazard(self, inst_a_dec, inst_b_dec):
        haz = False
        if inst_a_dec[0] == 2:
            haz=True
        if inst_b_dec[0] != 1:
            haz = True
        if inst_b_dec[-2] == inst_a_dec[3] and inst_b_dec[2] != 1:
            haz = True
        
        if haz:
            self.step_size = 2
        else:
            self.step_size = 4
        return haz