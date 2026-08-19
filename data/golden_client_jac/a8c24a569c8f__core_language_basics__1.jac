glob x = "global";

def outer -> None {
    x = "enclosing";

    def inner -> None {
        x = "local";
        print(x);  # "local" - found in Local scope
    }

    inner();
    print(x);  # "enclosing" - found in Enclosing scope
}
