glob counter: int = 0;

def increment -> None {
    global counter;  # Required!
    counter += 1;
}
