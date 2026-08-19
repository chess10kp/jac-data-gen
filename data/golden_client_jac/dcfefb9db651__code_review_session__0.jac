node Todo {
    has title: str;
    has completed: bool = False;
}

walker:priv GetStats {
    has total: int = 0;
    has completed: int = 0;

    can count with `root entry {
        visit [-->];
    }

    can tally with Todo entry {
        self.total += 1;
        if here.completed {
            self.completed += 1;
        }
    }

    can summarize with `root exit {
        report {
            "total": self.total,
            "completed": self.completed,
            "pending": self.total - self.completed,
            "completion_rate": (self.completed / self.total * 100.0) if self.total > 0 else 0.0
        };
    }
}
