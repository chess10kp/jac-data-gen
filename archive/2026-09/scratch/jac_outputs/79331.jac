"""Escapes characters you don't want in arguments (preventing shell injection)."""
def escapearg(args: str) -> str {
    special_chars = '#&;`|*?~<>^()[]{}$\\';
    for char in special_chars {
        args = args.replace(char, '');
    }
    return args;
}