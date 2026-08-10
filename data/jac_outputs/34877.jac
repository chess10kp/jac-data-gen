"""Whether the supplied command line has already been prefixed with an OS specific operation."""
def _is_prefixed(cmd_line: str | None) -> bool {
    if cmd_line is None {
        raise ValueError("CommandLine is required field for task.");
    }
    return cmd_line.startswith(('cmd.exe /c', 'cmd /c', '/bin/bash -c', '/bin/sh -c'));
}