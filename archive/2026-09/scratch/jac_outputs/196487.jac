"""
Given a list of command line arguments, quote them so they can be can be
printed on POSIX
"""
def quotePosix(args: list[str]) -> list[str] {
    def q(x: str) -> str {
        return "'" + x + "'" if " " in x else x;
    }
    return [q(x) for x in args];
}