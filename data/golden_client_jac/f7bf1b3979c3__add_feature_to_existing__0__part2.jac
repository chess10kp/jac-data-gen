node Item { has name: str = ""; }

walker Example {
    has count: int = 0;

    can traverse with Item entry {
        self.count += 1;
        print(f"Visiting {here.name}");
        visit [-->];
    }

    can finish with exit {
        print(f"Visited {self.count} items");
    }
}
