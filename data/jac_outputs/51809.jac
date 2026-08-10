"""Check two arrays for tolerance [1,2,3]==[1,2,3]; but [1,3,2]!=[1,2,3]."""
def are_eq(A: list[float], B: list[float], tolerance: float = 0.0001) -> bool {
    if len(A) != len(B) {
        return False;
    }
    for i in range(len(A)) {
        if abs(A[i] - B[i]) > tolerance {
            return False;
        }
    }
    return True;
}