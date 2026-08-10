"""assumption: package name starts with <host>/org/repo"""
def get_go_module_path(package: str) -> str {
    "/".join(package.split("/")[3:])
}