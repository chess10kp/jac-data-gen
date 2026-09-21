"""Public poll endpoint: vote and read live tallies over HTTP.

`vote` bumps a counter from its request body, `tally` reports counts
back; the entry block simulates a few clicks for standalone runs.
"""

node PollOption {
    has title: str;
    has votes: int = 0;
}

walker:pub setup_poll {
    has titles: list[str];

    can run with Root entry {
        for t in self.titles {
            here ++> PollOption(title=t);
        }
    }
}

walker:pub vote {
    has choice: str;

    can run with Root entry {
        for opt in [-->][?:PollOption] {
            if opt.title == self.choice {
                opt.votes += 1;
                report {"counted": opt.title, "total": opt.votes};
                disengage;
            }
        }
        report {"error": "unknown option", "choice": self.choice};
    }
}

walker:pub tally {
    can run with Root entry {
        report {opt.title: opt.votes for opt in [-->][?:PollOption]};
    }
}

with entry {
    root spawn setup_poll(titles=["The Dispossessed", "Snow Crash", "Ancillary Justice"]);

    # Pretend these arrived as HTTP POSTs.
    root spawn vote(choice="Snow Crash");
    root spawn vote(choice="Snow Crash");
    root spawn vote(choice="The Dispossessed");

    result = root spawn tally();
    print(result.reports);
}
