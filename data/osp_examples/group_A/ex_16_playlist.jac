"""Road trip playlist: creating nodes inline inside connections.

Tracks never need their own variables -- each one is constructed
right where it is connected, and the whole queue hangs off root in
one statement. A player walker then walks the queue in order.
"""

node Track {
    has title: str = "";
    has artist: str = "";
    has seconds: int = 0;
}

walker Player {
    has elapsed: int = 0;

    can start with Root entry {
        print("Pressing play...");
        visit [-->];
    }

    can play with Track entry {
        self.elapsed += here.seconds;
        print(f"Now playing: {here.title} by {here.artist} ({here.seconds}s)");
        visit [-->];
    }

    can finish with Track exit {
        print(f"Total runtime so far: {self.elapsed // 60}m {self.elapsed % 60}s");
    }
}

with entry {
    # Inline creation: no intermediate variables needed.
    root ++> Track(title="Nightcall", artist="Kavinsky", seconds=258)
        ++> Track(title="Genesis", artist="Grimes", seconds=249)
        ++> Track(title="Midnight City", artist="M83", seconds=244);

    root spawn Player();
}
