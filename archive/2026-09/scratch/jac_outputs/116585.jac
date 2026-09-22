"""Verify the correctness of the YYC rules."""
def _check(rule1: list[int], rule2: list[list[int]]) -> bool {
    for val in rule1 {
        if val != 0 and val != 1 {
            return False;
        }
    }
    if sum(rule1) != 2 {
        return False;
    }
    if rule1[0] == rule1[1] {
        same = [0, 1, 2, 3];
    } elif rule1[0] == rule1[2] {
        same = [0, 2, 1, 3];
    } else {
        same = [0, 3, 1, 2];
    }
    for row in rule2 {
        if (
            row[same[0]] + row[same[1]] != 1
            or row[same[0]] * row[same[1]] != 0
        ) {
            return False;
        }
        if (
            row[same[2]] + row[same[3]] != 1
            or row[same[2]] * row[same[3]] != 0
        ) {
            return False;
        }
    }
    return True;
}