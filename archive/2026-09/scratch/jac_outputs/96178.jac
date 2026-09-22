"""Count errors in nodes."""
def parse_errors(nodes: list[tuple[str, str]], errors: dict[str, str]) -> tuple[int, int, str] {
    key_errors = len([1 for (_, snd) in nodes if snd == errors['key_str']]);
    val_errors = len([1 for (_, snd) in nodes if snd == errors['val_str']]);
    output = 'Key Errors:\t' + str(key_errors);
    output += '\nValue Errors:\t' + str(val_errors);
    return (key_errors, val_errors, output);
}