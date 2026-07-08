# stateless
from .decoder import Decoder
from .alu import ALU

#stateful
from .pipeline import Pipeline
from .ram import Ram
from .register_file import RegFile
from .clock import Clock

decoder = Decoder()
alu = ALU()

pipeline_1 = Pipeline(3)
pipeline_2 = Pipeline(3)
ram = Ram(2**16, 16)
pram = Ram(2**16, 16)
register_file = RegFile(16, 16)
clk = Clock()

current_pc = 0
stalling_for = 2

bus = 0
do_jmp = 0


def run_mem_op(decoded):
    opcode = decoded[1]
    address = decoded[-1]
    data= decoded[-2]
    if opcode == 0:
        return ram.read(address, 1)
    if opcode == 1:
        ram.write(address, [data])
        return 0
    if opcode == 2:
        return pram.read(address, 1)
    if opcode == 3:
        pram.write(address, [data])
        return 0
    

while True:
    inst64 = ram.read(current_pc, 4)
    inst_a_rd = (inst64 >> 32) & 0xFFFFFFFF
    inst_b_rd = inst64 & 0xFFFFFFFF
    haz = clk.compute_hazard(
        decoder.decode(inst_a_rd),
        decoder.decode(inst_b_rd)
    )
    clk.step(bus,do_jmp)  # first time pipeline contains fuck all, it's fine

    if haz:
        inst_b_rd = 0

    exec_1 = pipeline_1.step(inst_a_rd)
    exec_2 = pipeline_2.step(inst_b_rd)

    dec_1 = decoder.decode(exec_1)
    dec_2 = decoder.decode(exec_2)

    dec_1[4] == register_file.read([dec_1[4]])
    dec_2[4] == register_file.read([dec_2[4]])
    if dec_1[2] == 1:
        dec_1[5] == register_file.read([dec_1[5]])
    if dec_2[2] == 1:
        dec_2[5] == register_file.read([dec_2[5]])

    if stalling_for > 0:
        stalling_for -=1
        continue

    bus = 0
    do_jmp = 0
    match dec_1[0]:
        case 0: # io
            bus = 0 # NOT IMPLEMENTED
        case 1: # alu
            bus = alu.run_op(dec_1[1], dec_1[-2], dec_1[-1])
        case 2: # jmp
            bus = dec_1[-1]
            do_jmp = ((dec_1[1] & dec_1[-2] & 0b111)>0)^(dec_1[1]>>3)
            stalling_for = 2
        case 3: # mem
            bus = run_mem_op(dec_1)
        
    register_file[dec_1[3]] = bus

    if dec_2[0] == 1:
        register_file[dec_1[3]] = alu.run_op(dec_2[1], dec_2[-2], dec_2[-1])