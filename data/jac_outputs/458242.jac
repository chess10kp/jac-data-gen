"""Get the section header type."""
def get_sh_type(sh_type: int) -> str {
    match sh_type {
        case 0:
            return 'SHT_NULL';
        case 1:
            return 'SHT_PROGBITS';
        case 2:
            return 'SHT_SYMTAB';
        case 3:
            return 'SHT_STRTAB';
        case 4:
            return 'SHT_RELA';
        case 5:
            return 'SHT_HASH';
        case 6:
            return 'SHT_DYNAMIC';
        case 7:
            return 'SHT_NOTE';
        case 8:
            return 'SHT_NOBITS';
        case 9:
            return 'SHT_REL';
        case 10:
            return 'SHT_SHLIB';
        case 11:
            return 'SHT_DYNSYM';
        case 14:
            return 'SHT_INIT_ARRAY';
        case 15:
            return 'SHT_FINI_ARRAY';
        case 16:
            return 'SHT_PREINIT_ARRAY';
        case 17:
            return 'SHT_GROUP';
        case 18:
            return 'SHT_SYMTAB_SHNDX';
        case 19:
            return 'SHT_NUM';
        case 0x60000000:
            return 'SHT_LOOS';
        case _:
            print('Unable to match {} to a sh_type.'.format(sh_type));
            raise ValueError;
    }
}