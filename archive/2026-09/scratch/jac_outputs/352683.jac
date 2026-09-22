"""Shell command that lists the compiler info and include directories."""
def ShellCommand(cc_compiler_path: str, command_line_list: list[str] = []) -> list[str] {
    return [cc_compiler_path, "-E", "-x", "c++"] + command_line_list + ["-", "-v", "/dev/null"];
}