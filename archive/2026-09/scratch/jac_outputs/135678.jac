"""test if path_to_exe was installed as part of the OS."""
def is_os_tool(path_to_exe: str) -> bool {
    path_to_exe.startswith('/usr/bin')
}