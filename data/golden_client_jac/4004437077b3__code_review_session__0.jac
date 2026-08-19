import sys;

with entry {
    args = sys.argv;
    print("argc:", len(args));
    for arg in args[1:] {
        print("arg:", arg);
    }
    if "--verbose" in args {
        print("Verbose mode enabled");
    }
}
