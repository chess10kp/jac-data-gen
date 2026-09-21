"""Knowledge-graph question answering with multi-hop typed queries.

People, companies and cities are linked by typed relation edges. An
analyst walker parked on one person answers three questions purely by
composing spatial queries: same-company colleagues and where they live,
companies headquartered in the person's own city, and colleagues who
joined recently (edge attribute predicate).
"""

node Person {
    has name: str;
}

node Company {
    has name: str;
}

node City {
    has name: str;
}

edge WorksAt: Person --> Company {
    has since: int;
}

edge LivesIn: Person --> City {}

edge HqIn: Company --> City {}

walker Analyst {
    can investigate with Person entry {
        me = here.name;

        # Q1: people at my company (hop to the company, then back along
        # its incoming WorksAt edges), and where each of them lives.
        mates = [here ->:WorksAt:-> <-:WorksAt:<-];
        print(f"Q1: Where do {me}'s colleagues live?");
        for mate in mates {
            if mate.name == me {
                continue;
            }
            home = [mate ->:LivesIn:->];
            city_name = home[0].name;
            print(f"  {mate.name} lives in {city_name}");
        }

        # Q2: companies headquartered in the city I live in.
        local_hq = [here ->:LivesIn:-> <-:HqIn:<-];
        print(f"Q2: Companies headquartered in {me}'s city:");
        for company in local_hq {
            print(f"  {company.name}");
        }

        # Q3: colleagues who joined the same company since 2021
        # (edge attribute predicate on the return hop).
        newcomers = [here ->:WorksAt:-> <-:WorksAt:since >= 2022:<-];
        print(f"Q3: Colleagues who joined since 2022:");
        for mate in newcomers {
            if mate.name == me {
                continue;
            }
            print(f"  {mate.name}");
        }
    }
}

with entry {

    # Reset leftovers from any previous run of this demo.
    for stale_node in [root -->][?:Person] {
        del stale_node;
    }
    for stale_node in [root -->][?:Company] {
        del stale_node;
    }
    for stale_node in [root -->][?:City] {
        del stale_node;
    }
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    carol = Person(name="Carol");
    dave = Person(name="Dave");

    acme = Company(name="Acme Robotics");
    globex = Company(name="Globex AI");

    metropolis = City(name="Metropolis");
    gotham = City(name="Gotham");

    alice +>: WorksAt(since=2019) :+> acme;
    bob +>: WorksAt(since=2023) :+> acme;
    carol +>: WorksAt(since=2022) :+> acme;
    dave +>: WorksAt(since=2018) :+> globex;

    alice +>: LivesIn() :+> metropolis;
    bob +>: LivesIn() :+> gotham;
    carol +>: LivesIn() :+> metropolis;
    dave +>: LivesIn() :+> metropolis;

    acme +>: HqIn() :+> metropolis;
    globex +>: HqIn() :+> gotham;

    alice spawn Analyst();
}
