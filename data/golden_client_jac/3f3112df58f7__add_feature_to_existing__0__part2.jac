# greet.jac
import sys;

with entry {
    name = sys.argv[1] if len(sys.argv) > 1 else "World";
    greeting = sys.argv[2] if len(sys.argv) > 2 else "Hello";
    print(f"{greeting}, {name}!");
}
