BLOCKS = 4
block_hex = 4
raw_data = ''

base_path = "/home/kenzo/Desktop/cpu-verilog/reg_data"
filename = 'ram'

with open(f'{base_path}/{filename}.mem', 'r') as f:
    for line in f.readlines():
        raw_data += line.replace(' ','').strip()

chunks = [raw_data[i:i + block_hex] for i in range(0, len(raw_data), block_hex)]

bank_data = [[] for _ in range(BLOCKS)]

for bank,data in enumerate(chunks):
    mod_bank = bank%4
    bank_data[mod_bank].append(data)

for i, item in enumerate(bank_data):
    with open(f'{base_path}/{filename}_{i}.mem', 'w') as f:
        f.write('\n'.join(item))
