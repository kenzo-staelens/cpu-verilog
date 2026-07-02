from compiler.directives.directives import Section, Org
from typing import cast
from .base_processor import BaseProcessor

# stitch sections together and lay them out in order for proper resolving
class Organizer(BaseProcessor):
    def __init__(self, instructions, error_msg = "error while laying out sections"):
        super().__init__(instructions, error_msg)
        self.current_address = 0
        self.shards = {
            name: {} for name in Section._ALLOW_SECTIONS
        }
        self.shard_counters = {
            name: 0 for name in Section._ALLOW_SECTIONS
        }
        self.current_section = None
    
        self.instruction_shards = {
            name: [] for name in Section._ALLOW_SECTIONS
        }
        self.first_valid_address = 0

    def collect_section_starts(self):
        for i, inst in enumerate(self.instructions):
            if isinstance(inst, Section):
                self.current_section = inst.name
                next_inst = self.instructions[i+1]
                if not isinstance(next_inst, Org):
                    self.shards[self.current_section][self.shard_counters[self.current_section]] = (i, True)
                else:
                    # this really just generates a marker for later debugging
                    next_inst._gen_from = inst.name
                continue
            if isinstance(inst, Org):
                if self.current_section is None:
                    raise SyntaxError('Cannot declare .org directive outside of a section')
                self.shards[self.current_section][inst._align_to.value] = (i, False)  # index
                self.shard_counters[self.current_section] = i
            else:
                self.shard_counters[self.current_section] += 2

    def reorganize_sections(self):
        for shardkey, shard_starts in self.shards.items():
            working_shard = cast(list, self.instruction_shards[shardkey])
            self.first_valid_address = 0
            for address, instruction_info in sorted(cast(dict,shard_starts).items()):
                if address < self.first_valid_address:
                    raise RuntimeError(f'Failed to lay out section {shardkey}. '
                                       f'Attempting to write instructions to {address} while first '
                                       f'valid address is {self.first_valid_address}'
                    )
                instruction_index, phantom = instruction_info
                print(phantom)
                i = instruction_index
                # scrap until next item is an instruction
                while (i < len(self.instructions)-1) and isinstance(self.instructions[i+1], (Org, Section)):
                    i+= 1
                
                inst_head = self.instructions[i]
                if isinstance(inst_head, Org):
                    working_shard.append(
                        inst_head
                    )
                elif isinstance(inst_head, Section):
                    section_org = Org(inst_head.line_nr,inst_head.line_src)
                    section_org.parse_args([str(address)])
                    section_org._phantom = (phantom)
                    section_org._gen_from = inst_head.name
                    working_shard.append(
                        section_org
                    )
                i += 1
                while (i < len(self.instructions)) and not isinstance(self.instructions[i], (Org, Section)):
                    working_shard.append(self.instructions[i])
                    self.first_valid_address += 2  # should be number of addresses consumed but sure hardcode 2 for now
                    i += 1
        
        res = sum(self.instruction_shards.values(), start=[])
        self.instructions = res
        self.fix_line_nr()
        return self.instructions

    def fixup_section_offsets(self):
        pass

    def _process(self):
        self.collect_section_starts()
        self.reorganize_sections()
        self.fixup_section_offsets()
        return self.instructions
        