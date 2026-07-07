class Pipeline():
    def __init__(self, stages):
        self.stages = stages
        self.mem = [0]*stages

    def step(self, input):
        for i in range(self.stages-1, 0, -1):
            self.mem[i] = self.mem[i-1]
        self.mem[i] = input
        return self.mem[-1]
    