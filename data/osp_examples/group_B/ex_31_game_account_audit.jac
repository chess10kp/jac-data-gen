"""Game account moderation sweep.

Account is the base archetype; MemberAccount and AdminAccount extend
it. The auditor walks a mixed population, greets each account with a
typed context block, and the lobby desk uses an anonymous ability
(``can admit with entry``) that fires for every visitor regardless of
walker type.
"""

node Account {
    has username: str;
    has reputation: int = 0;

    def describe() -> str {
        return f"account {self.username}";
    }
}

node MemberAccount(Account) {
    has joined: str = "";

    override def describe() -> str {
        return f"member {self.username} (joined {self.joined})";
    }
}

node AdminAccount(Account) {
    has level_name: str = "";

    override def describe() -> str {
        return f"admin {self.username} [{self.level_name}]";
    }
}

# Anonymous node ability: fires for EVERY walker that visits.
node WelcomeDesk {
    can admit with entry {
        print(f"desk admits a {type(visitor).__name__}");
    }
}

walker ModerationBot {
    has admins_seen: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can check_in with WelcomeDesk entry {
        visit [-->];
    }

    can audit with Account entry {
        ->AdminAccount{
            self.admins_seen += 1;
            here.reputation += 5;
            print(f"audited {here.describe()} -- reputation boosted to "
                  f"{here.reputation}");
        }
        ->MemberAccount{
            print(f"audited {here.describe()} (reputation "
                  f"{here.reputation})");
        }
    }
}

with entry {
    desk = WelcomeDesk();
    root ++> desk;

    m1 = MemberAccount(username="pixelpaw", joined="2023-04-11");
    m2 = MemberAccount(username="quartzfinch", joined="2024-01-02");
    a1 = AdminAccount(username="nightwarden", level_name="senior");
    desk ++> m1;
    desk ++> m2;
    desk ++> a1;

    bot = ModerationBot();
    root spawn bot;
    print(f"bot saw {bot.admins_seen} admin account(s)");
}
