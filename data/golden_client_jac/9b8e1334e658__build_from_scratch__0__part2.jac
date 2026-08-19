# Wrong (Python style) - won't parse
# if condition:
#     do_something()

# Correct
def do_something() -> None {
    print("done");
}

with entry {
    condition = True;
    if condition {
        do_something();
    }
}
