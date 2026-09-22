"""Make sure that the path between the term and the lowest common head is in a certain direction."""
def check_direction(lch: object, hs: list[object], f_dir: Callable[[object], object]) -> bool {
    return `any(
        modifier not in f_dir(head) for (head, modifier) in zip([lch] + hs[:-1], hs)
    );
}