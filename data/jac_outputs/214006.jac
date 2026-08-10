"""Create a epilog string for the specified commands."""
def _format_epilog(commands: list[tuple[object, str, str | None]]) -> str {
    lines = ["Commands:"];
    for command in commands {
        name = command[1];
        desc = command[2] or " ";
        for (index, item) in enumerate(desc.splitlines()) {
            item = item.strip();
            if index == 0 {
                line = "  %-16s%s" % (name, item);
            } else {
                line = (" " * 18) + item;
            }
            lines.append(line);
        }
    }
    return '\r\n'.join(lines);
}