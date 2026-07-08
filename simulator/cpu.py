
# stateless
from simulator.decoder import Decoder
from simulator.alu import ALU

#stateful
from simulator.pipeline import Pipeline
from simulator.ram import Ram
from simulator.register_file import RegFile
from simulator.clock import Clock


class CPU:
    def __init__(self, program_file):
        self.decoder = Decoder()
        self.alu = ALU()
    
        self.pipeline_1 = Pipeline(3)
        self.pipeline_2 = Pipeline(3)
        self.ram = Ram(2**16, 16)
        self.ram.load_file(program_file)
        self.pram = Ram(2**16, 16)
        self.register_file = RegFile(16, 16)
        self.clk = Clock()
    
        self.current_pc = 0
        self.stalling_for = 2
    
        self.bus = 0
        self.do_jmp = 0

        self.incoming_io_data = 0
        self.outgoing_io_data = 0
        self.io_status = 0
        self.inst64 = self.ram.read(0,4)


    def run_mem_op(self, decoded):
        opcode = decoded.opcode
        address = decoded.get_b()
        data= decoded.arg_a
        if opcode == 0:
            return self.ram.read(address, 1)
        if opcode == 1:
            self.ram.write(address, [data])
            return 0
        if opcode == 2:
            return self.pram.read(address, 1)
        if opcode == 3:
            self.pram.write(address, [data])
            return 0

    def run_io_op(self, decoded):
        opcode = decoded.opcode
        data= decoded.arg_a
        if opcode == 0:
            return 0
        if opcode == 1:
            return self.current_pc
        if opcode == 2:
            return self.incoming_io_data
        if opcode == 3:
            self.outgoing_io_data = data
            return 0
        if opcode == 4:
            return self.io_status
        if opcode == 5:
            self.io_device = data
            return 0
        return 0

    def step(self):
        self.inst64 = self.ram.read(self.clk.pc, 4)
        inst_a_rd = (self.inst64 >> 32) & 0xFFFFFFFF
        inst_b_rd = self.inst64 & 0xFFFFFFFF
        haz = self.clk.compute_hazard(
            self.decoder.decode(inst_a_rd),
            self.decoder.decode(inst_b_rd)
        )
        self.clk.step(self.bus,self.do_jmp)  # first time pipeline contains fuck all, it's fine

        if haz:
            inst_b_rd = 0

        exec_1 = self.pipeline_1.step(inst_a_rd)
        exec_2 = self.pipeline_2.step(inst_b_rd)

        dec_1 = self.decoder.decode(exec_1)
        dec_2 = self.decoder.decode(exec_2)

        dec_1 = dec_1.set_a(self.register_file.read(dec_1.arg_a))
        dec_2 = dec_2.set_a(self.register_file.read(dec_2.arg_a))
        if dec_1.immediate == 1:
            dec_1 = dec_1.set_b(self.register_file.read(dec_1.arg_b))
        if dec_2.immediate == 1:
            dec_2= dec_2.set_b(self.register_file.read(dec_2.arg_b))

        self.bus = 0
        self.do_jmp = 0

        if self.stalling_for > 0:
            self.stalling_for -=1
            self.bus = 0
            return

        match dec_1.mode:
            case 0: # io
                self.bus = self.run_io_op(dec_1) # NOT IMPLEMENTED
            case 1: # alu
                self.bus = self.alu.run_op(dec_1.opcode, dec_1.arg_a, dec_1.get_b())
            case 2: # jmp
                self.bus = dec_1.get_b()
                self.do_jmp = (((dec_1.opcode & dec_1.get_b()) & 0b111)>0)^(dec_1.opcode>>3)
                self.stalling_for = 1 # ??
            case 3: # mem
                self.bus = self.run_mem_op(dec_1)
        print(dec_1,'\n', dec_2,'\n', dec_1.get_b(), self.do_jmp)

        self.register_file.write(dec_1[3], self.bus)

        if dec_2.mode == 1:
            self.register_file.write(
                dec_2[3],
                self.alu.run_op(dec_2[1], dec_2[-2], dec_2[-1])
            )

    def set_io(self, value):
        self.incoming_io_data = value
    
    def get_io(self):
        return self.outgoing_io_data

    def set_io_status(self, value):
        self.io_status = value