class RegFile:
    def __init__(self, register_count, word_width):
        self.register_count = register_count
        self.word_width = word_width
        self.mem = [0]*(register_count)

    def read(self, address) -> int:
        if address == 0:
            return 0
        return self.mem[address]
    
    def write(self, address, data: int):
        if address == 0:
            return
        self.mem[address] = data