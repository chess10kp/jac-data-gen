obj GuestEntry { has id: str, name: str, message: str, created_at: str; }

edge OnDay {}
edge Signed {}

node Day { has date: str = ""; }
node Visitor {
    has name: str = "", message: str = "", created_at: str = "";

    def to_view -> GuestEntry {
        return GuestEntry(id="", name=self.name, message=self.message, created_at=self.created_at);
    }
}

walker sign_guestbook {
    has name: str = "", message: str = "", reports: list[GuestEntry] = [];

    can run with Root entry {
        if not self.message.strip() {
            return;
        }
        today = "2020-01-01";
        visit [root-->[?:Day, date == today]] else {
            fresh_day = root +>: OnDay() :+> Day(date=today);
            grant(fresh_day[0], level=ConnectPerm);
            visit fresh_day;
        }
    }

    can sign with Day entry {
        fresh = here +>: Signed() :+> Visitor(
            name=self.name.strip()[:40] or "anonymous",
            message=self.message.strip()[:200],
            created_at="2020-01-01T00:00:00Z"
        );
        grant(fresh[0], level=ReadPerm);
        report fresh[0].to_view();
    }
}

with entry {
    res = root spawn sign_guestbook(name="  Alice  ", message="  hello world  ");
    ge = res.reports[0];
    print("name:", ge.name);
    print("message:", ge.message);
    print("created_at:", ge.created_at);

    anon = root spawn sign_guestbook(name="", message="second");
    print("anon_name:", anon.reports[0].name);

    day_count = len([root-->[?:Day]]);
    visitor_count = 0;
    for d in [root-->[?:Day]] {
        visitor_count += len([d-->[?:Visitor]]);
    }
    print("day_count:", day_count);
    print("visitor_count:", visitor_count);
}
