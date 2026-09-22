"""for splitting user input"""
def lispi(a: int | str) -> tuple[int, int] {
    a = int(a);
    return (a // 10, a % 10);
}