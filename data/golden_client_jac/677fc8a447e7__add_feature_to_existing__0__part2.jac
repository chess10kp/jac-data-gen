glob counter: int = 0;

def increment -> None {
    global counter;
    counter += 1;
}

# New: matching decrement using the global declaration
def decrement -> None {
    global counter;
    counter -= 1;
}

def outer -> None {
    x = 10;
    def inner -> None {
        nonlocal x;
        x += 1;
    }
    inner();
    print(x);
}

with entry {
    increment();
    increment();
    decrement();
    print(counter);
    outer();
}
