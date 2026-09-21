"""Cave expedition transcript.

Entry abilities stamp arrival the moment a chamber is reached; exit
abilities stamp departure only after every deeper chamber is done, so
the transcript shows entries in walking order and exits unwinding in
reverse (innermost chamber leaves first).
"""

node Chamber {
    has label: str;

    can arrive with Explorer entry {
        print(f"ENTER {self.label}");
    }

    can depart with Explorer exit {
        print(f"EXIT  {self.label}");
    }
}

walker Explorer {
    has depth: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can explore with Chamber entry {
        self.depth += 1;
        visit [-->];
    }
}

with entry {
    mouth = Chamber(label="Mouth");
    tunnel = Chamber(label="Tunnel");
    cavern = Chamber(label="Crystal Cavern");
    root ++> mouth ++> tunnel ++> cavern;

    result = root spawn Explorer();
    print(f"explorer reached depth {result.depth}");
}
