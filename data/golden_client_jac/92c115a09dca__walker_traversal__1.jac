node Item { has value: int = 0; }

walker Example {
    can collect with Item entry {
        report here.value;  # Continues execution
        visit [-->];        # Still runs

        return;             # Would stop the walker here
    }
}
