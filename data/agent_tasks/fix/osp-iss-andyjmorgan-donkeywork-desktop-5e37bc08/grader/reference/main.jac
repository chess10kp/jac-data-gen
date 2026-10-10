"""Terminal session graph demo: revoke a session and cascade invalidation through its PTY and client."""

node TerminalSession {
    has title: str = "";
    has year: int = 0;
    has available: bool = True;
    has account: str = "terminal";
    has epoch: int = 0;
    has mode: str = "desktop";
}

node PtyProcess {
    has title: str = "";
    has year: int = 0;
    has available: bool = True;
    has process_id: int = 0;
    has process_group: int = 0;
    has width: int = 80;
    has height: int = 24;
}

node TerminalClient {
    has title: str = "";
    has year: int = 0;
    has available: bool = True;
    has client_id: str = "";
}

edge Contains: any --> any {
    has label: str = "";
}

edge Runs: any --> any {
    has epoch: int = 0;
}

edge AttachedTo: any --> any {
    has terminal: str = "";
}

walker SessionRevoker {
    has depth: int = 0;
    has max_depth: int = 4;
    has invalidated: int = 0;

    can start with Root entry {
        visit [->:Contains:->] else {
            disengage;
        }
    }

    can revoke with TerminalSession entry {
        if self.depth >= self.max_depth {
            print("cycle or depth limit reached at session");
            disengage;
        }
        self.depth += 1;
        here.available = False;
        self.invalidated += 1;
        print(f"revoked session {here.title}, epoch {here.epoch}");
        visit [->:Runs:->] else {
            disengage;
        }
    }

    can stop with PtyProcess entry {
        if self.depth >= self.max_depth {
            print("cycle or depth limit reached at PTY");
            disengage;
        }
        self.depth += 1;
        here.available = False;
        self.invalidated += 1;
        print(f"stopped PTY group {here.process_group}");
        visit [->:AttachedTo:->] else {
            disengage;
        }
    }

    can disconnect with TerminalClient entry {
        here.available = False;
        self.invalidated += 1;
        print(f"disconnected client {here.client_id}");
    }
}

with entry {
    session = TerminalSession(
        title="browser-terminal",
        year=2024,
        account="fixed-terminal",
        epoch=7,
        mode="desktop"
    );
    pty = PtyProcess(
        title="linux-pty",
        year=2024,
        process_id=4102,
        process_group=4102,
        width=3840,
        height=2160
    );
    client = TerminalClient(
        title="xterm-client",
        year=2024,
        client_id="browser-17"
    );

    root +>:Contains(label="authorized-session"):+> session;
    session +>:Runs(epoch=7):+> pty;
    pty +>:AttachedTo(terminal="browser"):+> client;

    root spawn SessionRevoker();
}
