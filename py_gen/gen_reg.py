from argparse import ArgumentParser

DEFAULT_BLOCKS = 4
block_hex = 4
raw_data = ''

parser = ArgumentParser(__name__)
parser.add_argument('--build-dir', required=True)
parser.add_argument('--basename', required=True)
parser.add_argument('--outdir', required=True)
parser.add_argument('--banks', default=DEFAULT_BLOCKS)
args = parser.parse_args()

base_outname = 'ram'

with open(f'{args.build_dir}/{args.basename}.mem', 'r') as f:
    for line in f.readlines():
        raw_data += line.replace(' ','').strip()

chunks = [raw_data[i:i + block_hex] for i in range(0, len(raw_data), block_hex)]

bank_data = [[] for _ in range(args.banks)]

for bank,data in enumerate(chunks):
    mod_bank = bank%4
    bank_data[mod_bank].append(data)

for i, item in enumerate(bank_data):
    with open(f'{args.outdir}/{base_outname}_{i}.mem', 'w') as f:
        f.write('\n'.join(item))
