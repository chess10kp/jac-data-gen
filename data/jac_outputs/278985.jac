"""Clear spaces and tabs before and after an instruction line."""
def cleaning_space(string_inst: str) -> str {
    while string_inst[0] == ' ' or string_inst[0] == "\t" {
        string_inst = string_inst[1:];
    }
    while string_inst[-1] == ' ' or string_inst[-1] == '\t' {
        string_inst = string_inst[:-1];
    }
    return string_inst;
}