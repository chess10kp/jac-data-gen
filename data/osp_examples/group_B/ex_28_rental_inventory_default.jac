"""Rental shop inventory audit.

The auditor triggers on the base MediaItem type and gives books and
DVDs their own typed context blocks; anything that is neither (a bare
MediaItem, e.g. an unlabelled archive reel) falls through to default
handling guarded by a kind flag.
"""

node MediaItem {
    has title: str;

    def describe() -> str {
        return f"'{self.title}'";
    }
}

node Book(MediaItem) {
    has author: str;

    override def describe() -> str {
        return f"book '{self.title}' by {self.author}";
    }
}

node Dvd(MediaItem) {
    has runtime_min: int;

    override def describe() -> str {
        return f"dvd '{self.title}' ({self.runtime_min} min)";
    }
}

walker InventoryAudit {
    has counted: int = 0;
    has misc_count: int = 0;
    has kind: str = "";

    can start with Root entry {
        visit [-->];
    }

    can audit with MediaItem entry {
        self.counted += 1;
        self.kind = "misc";

        ->Book{
            self.kind = "book";
            print(f"shelved {here.describe()}");
        }
        ->Dvd{
            self.kind = "dvd";
            print(f"shelved {here.describe()}");
        }

        # Default branch: bare MediaItems match neither block above.
        if self.kind == "misc" {
            self.misc_count += 1;
            print(f"default handling for unclassified item {here.describe()}");
        }
    }
}

with entry {
    dracula = Book(title="Dracula", author="Stoker");
    dune = Book(title="Dune", author="Herbert");
    metropolis = Dvd(title="Metropolis", runtime_min=153);
    reel = MediaItem(title="Archive Reel 07");
    root ++> dracula ++> dune;
    root ++> metropolis;
    root ++> reel;

    audit = InventoryAudit();
    root spawn audit;
    print(f"audited {audit.counted} items "
          f"({audit.misc_count} needed default handling)");
}
