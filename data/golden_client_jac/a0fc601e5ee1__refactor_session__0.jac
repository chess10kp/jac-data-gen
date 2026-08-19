def demo_list() -> None {
    for item in [1, 2, 3] {
        print(item);
    }
}

def demo_range() -> None {
    for i in range(5) {
        print(i);
    }
}

def demo_enumerate() -> None {
    names = ["Alice", "Bob", "Carol"];
    for (i, name) in enumerate(names) {
        print(f"{i}: {name}");
    }
}

with entry {
    demo_list();
    demo_range();
    demo_enumerate();
}
