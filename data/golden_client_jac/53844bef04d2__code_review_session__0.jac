# models.jac
"""Task node definition."""

node Task {
    has title: str;
    has done: bool = False;

    def complete() -> None {
        self.done = True;
    }
}
