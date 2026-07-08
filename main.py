from simulator.cpu import CPU


cpu = CPU('programs/out/echo.prog')

cpu.io_status = 0b01

while True:
    cpu.step()
    print(cpu.register_file.mem)
    print(cpu.bus, cpu.clk.pc, cpu.stalling_for, f'{cpu.inst64:0>19_x}')
    input()
