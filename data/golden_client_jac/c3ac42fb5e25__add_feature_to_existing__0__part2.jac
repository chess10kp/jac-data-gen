glob counter: int = 0;

def increment -> None {
    global counter;
    counter += 1;
}

def decrement -> None {
    global counter;
    counter -= 1;
}

def reset -> None {
    global counter;
    counter = 0;
}
