from argparse import ArgumentParser
from processing import Parser, Resolver, Assembler

parser = ArgumentParser(__name__)
parser.add_argument('--filename', '-f', required=True)
parser.add_argument('--outfile', '-o', required=True)
parser.add_argument('--verbose', '-v', action='store_true')
parser.add_argument('--debug', '-d', action='store_true')

def render_state(args, instructions):
    if not args.verbose:
        return
    for line in instructions:
        if args.debug:
            print(repr(line))
        else:
            print(line)
    print()

if __name__ == '__main__':
    args = parser.parse_args()

    file_parser = Parser(args.filename)
    instructions = file_parser.parse_file()

    render_state(args, instructions)

    resolver = Resolver(instructions)
    resolver.resolve_addresses()
    render_state(args, instructions)
    
    assembler = Assembler(args.outfile, instructions)
    assembler.write_file(args.verbose)
