"""API service for arcade_leaderboard.

A minimal guestbook: messages are `Message` nodes on the shared `root`
graph. The `:pub` walkers are the HTTP API the service exposes.
"""

node Message {
    has author: str,
        text: str;
}

walker:pub PostMessage {
    """Append a message and report the created node."""
    has author: str,
        text: str,
        reports: list[Message] = [];

    can post with Root entry {
        report here ++> Message(author=self.author, text=self.text);
    }
}

walker:pub ListMessages {
    """Report every message in the guestbook."""
    has reports: list[Message] = [];

    can collect with Root entry {
        visit [-->];
    }

    can gather with Message entry {
        report here;
    }
}
