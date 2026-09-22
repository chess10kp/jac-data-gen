"""
Method converting a list of arguments/parameter in a command line format (to include in the execution of a program for exemple).
list --> str
"""
def commandLine(Argv: list[str]) -> str {
    assert `type(Argv) is list, "The argument of this method are the arguments to convert in the command line format. (type List)";
    commandLine = '';
    for i in Argv[1:] {
        commandLine += i + " ";
    }
    return commandLine;
}