from argparse import ArgumentParser
from compiler.processing import Parser, Resolver, Assembler

parser = ArgumentParser(__name__)
parser.add_argument('--filename', '-f', required=True)
parser.add_argument('--outfile', '-o', required=True)
parser.add_argument('--verbose', '-v', action='store_true')
parser.add_argument('--debug', '-d', action='store_true')
parser.add_argument('--dry-run', action='store_true')

def render_state(hdr, args, instructions):
    if not args.verbose:
        return
    print(hdr)
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

    render_state('parse', args, instructions)
    resolver = Resolver(instructions)
    instructions = resolver.resolve()
    render_state('resolve', args, instructions)
    
    assembler = Assembler(args.outfile, args.dry_run, instructions)
    assembler.write_file(args.verbose)
