node Person {
    has name: str;
    has birth_year: int;
    has depth: int = 0;
}

edge Parent {}

walker FindAncestors {
    has max_generations: int = 3;
    can explore with Person entry {
        print(f"{'  ' * here.depth}{here.name} (born {here.birth_year})");
        if here.depth < self.max_generations {
            visit [here <-:Parent:<-];
        }
    }
}
