"""Execution commands: run, version."""

obj Command {
    has name: str;
    has help: str;
    has group: str;
    has fn: object;
}

obj Registry {
    has commands: dict = {};

    def command(name: str, help: str = "", group: str = "general") -> object {
        def deco(fn: object) -> object {
            self.commands[name] = Command(name=name, help=help, group=group, fn=fn);
            return fn;
        }
        return deco;
    }
}

glob registry = Registry();

@registry.command(name="run", help="Run a Jac program", group="execution")
def run(filename: str, main: bool = True, cache: bool = True) -> int {
    print(f"Running {filename}");
    return 0;
}

@registry.command(name="version", help="Show the Jac version", group="info")
def version() -> int {
    print("jac 1.0.0");
    return 0;
}

with entry {
    print(f"Registered commands: {list(registry.commands.keys())}");
}
