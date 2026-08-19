glob x = "global";

def outer -> None {
    x = "enclosing";

    def inner -> None {
        x = "local";
        print(x);
    }

    inner();
    print(x);
}

# New: a function that reads the global x explicitly
def show_global -> None {
    print(x);
}

with entry {
    outer();
    show_global();
}
