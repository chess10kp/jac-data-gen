"""Convert a list of instructions into an easm op code string."""
def instruction_list_to_easm(instruction_list: list[dict[str, str]]) -> str {
    result = "";
    for instruction in instruction_list {
        result += "{} {}".format(instruction["address"], instruction["opcode"]);
        if "argument" in instruction {
            result += " " + instruction["argument"];
        }
        result += "\n";
    }
    return result;
}