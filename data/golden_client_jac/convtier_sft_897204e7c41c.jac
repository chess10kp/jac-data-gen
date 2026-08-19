obj ToggleSwitch {
    has on: bool = False;

    def toggle() -> None { self.on = not self.on; }
}

with entry {
    s = ToggleSwitch();
    s.toggle();
    s.toggle();
    print(s.on);
}
