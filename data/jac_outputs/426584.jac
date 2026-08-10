"""Tracks Santa's steps"""
def calculate(puzzle_input: str) -> int {
    x = y = rx = ry = 0;
    visited = set();
    robot = False;
    for step in puzzle_input {
        if step == "^" {
            if robot {
                ry += 1;
            } else {
                y += 1;
            }
        } elif step == "v" {
            if robot {
                ry -= 1;
            } else {
                y -= 1;
            }
        } elif step == "<" {
            if robot {
                rx -= 1;
            } else {
                x -= 1;
            }
        } elif step == ">" {
            if robot {
                rx += 1;
            } else {
                x += 1;
            }
        }
        if robot {
            visited.add((rx, ry));
            robot = False;
        } else {
            visited.add((x, y));
            robot = True;
        }
    }
    return len(visited);
}