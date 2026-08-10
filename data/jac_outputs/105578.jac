"""Returns true if the addition of the 'test' connection would create a cycle,
assuming that no cycle already exists in the graph represented by 'connections'."""
def creates_cycle(connections: list[tuple[int, int]], `test: tuple[int, int]) -> bool {
    (i, o) = `test;
    if i == o {
        return True;
    }
    visited = {o};
    while True {
        num_added = 0;
        for (a, b) in connections {
            if a in visited and b not in visited {
                if b == i {
                    return True;
                }
                visited.add(b);
                num_added += 1;
            }
        }
        if num_added == 0 {
            return False;
        }
    }
}