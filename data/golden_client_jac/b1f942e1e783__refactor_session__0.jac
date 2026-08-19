def check_conditions(condition: bool, other_condition: bool) -> None {
    if condition {
        print("Condition is true");
    } elif other_condition {
        print("Other condition is true");
    } else {
        print("Neither condition is true");
    }
}
def count_up() -> None {
    count = 0;
    while count < 3 {
        print(f"Count: {count}");
        count += 1;
    }
}
def count_range() -> None {
    for i = 0 to i < 5 by i += 1 {
        print(f"i: {i}");
    }
}
def iterate(collection: list) -> None {
    for item in collection {
        print(f"Item: {item}");
    }
}
with entry {
    check_conditions(True, False);
    count_up();
    count_range();
    iterate(["a", "b", "c"]);
}
