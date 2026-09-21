"""Epidemic simulation over a contact network.

People are connected by Contact edges carrying a strength. Each simulated
day an infection-sweep walker visits everyone: susceptible people compute
their exposure to infectious contacts and catch the infection
probabilistically (a seeded linear congruential generator keeps runs
reproducible), but state changes are applied only at the deferred root
exit so nobody infects their neighbours "later the same day".
"""

node Person {
    has name: str;
    has infected: bool = False;
    has next_state: bool = False;  # staged infection state for today
}

edge Contact: Person --> Person {
    has strength: float;
}

walker InfectionSweep {
    has beta: float = 0.5;   # transmissibility scale
    has seed: int = 42;      # LCG state, carried across days by the driver

    can start with Root entry {
        visit [-->];
    }

    can assess with Person entry {
        if here.infected {
            here.next_state = True;
            skip;
        }

        neighbors = [->:Contact:->];
        links = [edge ->:Contact:->];

        exposure = 0.0;
        for i in range(len(neighbors)) {
            if neighbors[i].infected {
                exposure += links[i].strength;
            }
        }

        # Seeded LCG roll in [0, 1).
        self.seed = (self.seed * 1103515245 + 12345) % 2147483648;
        roll = self.seed / 2147483648.0;

        here.next_state = exposure > 0.0 and roll < exposure * self.beta;
    }

    can apply_day with Root exit {
        # Deferred until everyone has been assessed: flip states together.
        people = [-->][?:Person];
        for p in people {
            p.infected = p.next_state;
        }
    }
}

with entry {
    for stale in [root -->][?:Person] {
        del stale;
    }

    people: list[Person] = [];
    names = ["Ava", "Bo", "Cy", "Di", "Ed", "Fay", "Gus", "Hal"];
    for nm in names {
        people.append(Person(name=nm));
    }
    ava = people[0]; bo = people[1]; cy = people[2]; di = people[3];
    ed = people[4]; fay = people[5]; gus = people[6]; hal = people[7];

    ava <+: Contact(strength=0.6) :+> bo;
    ava <+: Contact(strength=0.3) :+> cy;
    bo <+: Contact(strength=0.9) :+> di;
    cy <+: Contact(strength=0.4) :+> di;
    di <+: Contact(strength=0.7) :+> ed;
    ed <+: Contact(strength=0.5) :+> fay;
    fay <+: Contact(strength=0.2) :+> gus;
    gus <+: Contact(strength=0.8) :+> hal;

    # Hang the population off the persistent root so walkers can sweep it.
    root ++> people;

    # Patient zero.
    ava.infected = True;
    ava.next_state = True;

    print("Epidemic curve (seeded, reproducible):");
    rng_state = 987654321;
    prev_sick = 1;
    for day in range(1, 7) {
        result = root spawn InfectionSweep(beta=0.45, seed=rng_state);
        rng_state = result.seed;
        sick = 0;
        for p in people {
            if p.infected {
                sick += 1;
            }
        }
        print(f"  Day {day}: {sick - prev_sick} new case(s), {sick}/8 infected");
        prev_sick = sick;
    }
}
