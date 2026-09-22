glob BASE_ADDRESS = 0x10000;

"""Generate C source definition for a macro listing ELF symbols."""
def CSourceForElfSymbolListMacro(
    variable_prefix: str,
    names: list[str],
    name_offsets: list[int],
    base_address: int = BASE_ADDRESS,
    symbol_size: int = 16,
    spacing_size: int = 16
) -> str {
    out = r'''// Auto-generated macro used to list all symbols
// XX must be a macro that takes the following parameters:
//   name: symbol name (quoted).
//   str_offset: symbol name offset in string table
//   address: virtual address.
//   size: size in bytes
''';
    out += '#define LIST_ELF_SYMBOLS_%s(XX) \\\n' % variable_prefix;
    address = base_address;
    for (sym, offset) in zip(names, name_offsets) {
        out += '    XX("%s", %d, 0x%x, %d) \\\n' % (sym, offset, address, symbol_size);
        address += symbol_size + spacing_size;
    }
    out += '    // END OF LIST\n';
    return out;
}