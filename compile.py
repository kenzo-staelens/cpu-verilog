from argparse import ArgumentParser
from compiler.processing import Parser, MacroPreprocessor, Organizer, Resolver, Assembler
from compiler.processing.base_processor import BaseProcessor
from compiler.processing.assembler import WriteModes
from typing import cast

parser = ArgumentParser(__name__)
parser.add_argument('--filename', '-f', required=True)
parser.add_argument('--outfile', '-o', required=True)
parser.add_argument('--verbose', '-v', action='store_true')
parser.add_argument('--debug', '-d', action='store_true')
parser.add_argument('--dry-run', action='store_true')
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument('--hex', action='store_true')
group.add_argument('--bin', action='store_true')
group.add_argument('--exe', action='store_true')

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

    for processor_cls in cast(list[type[BaseProcessor]],[
        MacroPreprocessor,
        Organizer,
        # Resolver
    ]):
        processor = (processor_cls)(instructions)
        instructions = processor.process()
        render_state(str(processor_cls), args, instructions)
    
    # preprocessor = MacroPreprocessor(instructions)
    # instructions = preprocessor.process()
    # render_state('macros', args, instructions)

    # organizer = Organizer(instructions)
    # instructions = organizer.organize()    
    # render_state('organized', args, instructions)

    resolver = Resolver(instructions, 2**16-1)
    instructions = resolver.process()
    render_state('resolve', args, instructions)
    
    # todo config loader
    # todo include directives
    # todo proper sections
    if args.bin:
        assembler = Assembler(args.outfile, args.dry_run, instructions, mode=WriteModes.BIN)
    elif args.exe:
        assembler = Assembler(args.outfile, args.dry_run, instructions, mode=WriteModes.EXE)
    else:
        assembler = Assembler(args.outfile, args.dry_run, instructions)
    assembler.write_file()
