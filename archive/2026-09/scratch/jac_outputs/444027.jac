"""Return all the permutations of the list l.

Obivously this should only be used for extremely small lists (like less
than 9 members).
"""
def permutations(l: list[int]) -> list[list[int]] {
    if len(l) > 0 {
        return [
            ([x] + perms) for x in l
            for perms in permutations([e for e in l if e != x])
        ];
    }
    return [[]];
}