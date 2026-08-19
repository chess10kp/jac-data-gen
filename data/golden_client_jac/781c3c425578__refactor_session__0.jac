node Person {
    has name: str;
    has birth_year: int;
    has depth: int = 0;
}
edge Parent {}
def mark_depth(people: list, d: int) -> None {
    for p in people {
        p.depth = d;
    }
}
walker FindAncestors {
    has max_generations: int = 3;
    can start with Root entry;
    can explore with Person entry;
}
impl FindAncestors.start {
    visit [-->];
}
impl FindAncestors.explore {
    print(f"{'  ' * here.depth}{here.name} (born {here.birth_year})");
    if here.depth < self.max_generations {
        parents = [here <-:Parent:<-];
        mark_depth(parents, here.depth + 1);
        visit parents;
    }
}
with entry {
    alice = Person(name="Alice", birth_year=2000);
    bob = Person(name="Bob", birth_year=1975);
    carol = Person(name="Carol", birth_year=1978);
    dave = Person(name="Dave", birth_year=1950);
    eve = Person(name="Eve", birth_year=1952);
    bob +>:Parent:+> alice;
    carol +>:Parent:+> alice;
    dave +>:Parent:+> bob;
    eve +>:Parent:+> bob;
    root ++> alice;
    print("Family tree:");
    root spawn FindAncestors(max_generations=3);
}
