# utils.jac
def helper() -> str {
    return "I'm a helper";
}

# main.jac
import from utils { helper }

with entry {
    print(helper());
}
