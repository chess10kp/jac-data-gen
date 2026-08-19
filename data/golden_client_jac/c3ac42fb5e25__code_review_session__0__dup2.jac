glob counter: int = 0;

def increment -> int {
    global counter;  # Required!
    counter += 1;
    return counter;
}
