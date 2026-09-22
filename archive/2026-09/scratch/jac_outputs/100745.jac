"""Check the given function to see if it's an instruction."""
def is_instruction(func: object) -> bool {
    return bool(callable(func) and hasattr(func, 'instruction_name'));
}