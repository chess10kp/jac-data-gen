"""Org chart modelled as Employee nodes joined by Manages edges."""

node Employee {
    has name: str;
    has title: str = "";
    has salary: int = 0;
}

edge Manages: Employee --> Employee {}

walker Headcount {
    has count: int = 0;
    has started: bool = False;

    can tally with Employee entry {
        if self.started {
            self.count += 1;
        }
        self.started = True;
        visit [here ->:Manages:->];
    }

    can finish with exit {
        report self.count;
    }
}

walker PayrollTotal {
    has total: int = 0;

    can add with Employee entry {
        self.total += here.salary;
        visit [here ->:Manages:->];
    }

    can finish with exit {
        report self.total;
    }
}

walker ChainOfCommand {
    has names: list[str] = [];
    has started: bool = False;

    can climb with Employee entry {
        if self.started {
            self.names.append(here.name);
        }
        self.started = True;
        visit [here ->:Manages:->];
    }

    can finish with exit {
        report self.names;
    }
}

with entry:__main__ {
    ceo = Employee(name="Ada", title="CEO", salary=300);
    vp = Employee(name="Grace", title="VP Eng", salary=200);
    dev = Employee(name="Linus", title="Engineer", salary=120);
    ceo +>:Manages:+> vp;
    vp +>:Manages:+> dev;
    print((ceo spawn Headcount()).reports);
    print((ceo spawn PayrollTotal()).reports);
    print((dev spawn ChainOfCommand()).reports);
}
