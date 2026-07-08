# due to architecture limits ram is layed out in words rather than bytes
# at least we do not have to consider data races here
class Ram:
    def __init__(self, addresses, word_width):
        self.word_width = word_width
        self.addresses = addresses
        self.mem = [0]*addresses
    

    def load_file(self, filename):
        pass

    def read(self, address, num_words) -> int:
        fetch = self.mem[address: address+num_words]
        res = 0
        for item in fetch:
            res <<= self.word_width
            res += item
        return res
    
    def write(self, address, data_words: list[int]):
        for i, item in enumerate(data_words):
            self.mem[i] = item