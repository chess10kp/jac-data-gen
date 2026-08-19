glob counter: int = 0;

def increment() -> None {
    global counter;
    counter += 1;
}

with entry {
    increment();
    increment();
    print(counter);
}
