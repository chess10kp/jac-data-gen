# greet.jac
import sys;

with entry {
    name = sys.argv[1] if len(sys.argv) > 1 else "World";
    print(f"Hello, {name}!");
}
