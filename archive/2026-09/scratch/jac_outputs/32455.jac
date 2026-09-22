"""If first parameter is less than second parameter, stores 1 in third parameter.  Else stores 0 in third parameter.  Returns True"""
def intcode_seven(parameter_list: list[int], code_list: list[int]) -> bool {
    if parameter_list[0] < parameter_list[1] {
        code_list[parameter_list[2]] = 1;
    } else {
        code_list[parameter_list[2]] = 0;
    }
    return True;
}