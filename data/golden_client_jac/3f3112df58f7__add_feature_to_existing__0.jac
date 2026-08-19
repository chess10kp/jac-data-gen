with entry {
    name = sys.argv[1] if len(sys.argv) > 1 else "World";
    greeting = sys.argv[2];
    print(f"{greeting}, {name}!");
}
