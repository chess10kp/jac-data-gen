node Step { has label: str = ""; }

walker Logger {
    has trail: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    can enter with Step entry {
        print(f"ENTER: {here.label}");
        self.trail.append(here.label);
        visit [-->];
    }

    can leave with Step exit {
        print(f"EXIT: {here.label}");
    }

    can finish with Root exit {
        report self.trail;
    }
}
