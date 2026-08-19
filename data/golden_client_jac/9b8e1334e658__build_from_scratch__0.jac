def do_something() -> None {
    print("done");
}

with entry {
    condition = True;
    if condition {
        do_something();
    }
}
