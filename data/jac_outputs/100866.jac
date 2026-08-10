"""O(n**2)"""
def disjoint2(A: list[int], B: list[int], C: list[int]) -> bool {
    for a in A {
        for b in B {
            if a == b {
                for c in C {
                    if a == c {
                        return False;
                    }
                }
            }
        }
    }
    return True;
}