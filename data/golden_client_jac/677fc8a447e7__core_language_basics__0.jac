glob counter: int = 0;

def increment -> None {
    global counter;    # Declares intent to modify global
    counter += 1;
}

def outer -> None {
    x = 10;
    def inner -> None {
        nonlocal x;    # Declares intent to modify enclosing
        x += 1;
    }
    inner();
    print(x);  # 11
}
