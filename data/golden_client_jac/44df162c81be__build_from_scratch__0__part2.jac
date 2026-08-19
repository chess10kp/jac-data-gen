import os;
import from math { pi }


def double(x: int) -> int {
    return x * 2;
}


with entry {
    name: str = "alice";
    age: int = 30;
    tags: list[str] = ["a", "b"];
    meta: dict[str, int] = {"x": 1};
    manager: str | None = None;

    doubled: list[int] = [n * 2 for n in [1, 2, 3]];

    label: str = "adult" if age >= 18 else "minor";   # ternary: A if cond else B

    square = lambda(x: int) -> int { return x * x; }; # typed lambda with braces
    print(square(5));

    greeting = f"hello {name}, {len(tags)} tags";

    for n in doubled {
        if n > 4 {
            print(f"big: {n}");
        } elif n > 2 {
            print(f"mid: {n}");
        } else {
            print(f"small: {n}");
        }
    }

    try {
        value = int("not-a-number");
    } except ValueError as e {
        print(f"parse error: {str(e)}");
    }
}
