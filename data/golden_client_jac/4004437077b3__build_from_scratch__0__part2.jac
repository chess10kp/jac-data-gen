import sys;

with entry {
    args = sys.argv;
    print("argc:", len(args));
    for i in range(1, len(args)) {
        print("arg:", args[i]);
    }
    if "--verbose" in args {
        print("Verbose mode enabled");
    }
}
