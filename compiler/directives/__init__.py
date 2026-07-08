from .alignment import Org, Align
from .label import Label
from .macro import Macro, Endmacro
from .section import Section
from .data import Raw, Text

from compiler.objects.directive import Directive

NORMAL_DIRECTIVES: list[type[Directive]] = [
    Label,
    Macro,
    Endmacro,
    Org,
    Align,
    Raw,
    Text
]
# no leading dot
ABNORMAL_DIRECTIVES: list[type[Directive]] = [
    Section
]
DIRECTIVES: dict[str, type[Directive]] = {
    **{  # kinda cursed
        '.' + c._MNEMONIC: c
        for c in NORMAL_DIRECTIVES
    },
    **{  # kinda cursed
        c._MNEMONIC: c
        for c in ABNORMAL_DIRECTIVES
    }
}

__all__ = [
    DIRECTIVES,
    ABNORMAL_DIRECTIVES
]