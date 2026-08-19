node Room {
    has name: str;
}

walker Explorer {
    has rooms_visited: int = 0;

    can explore with Room entry {
        self.rooms_visited += 1;
        print(f"In {here.name}, visited {self.rooms_visited} rooms");
        visit [-->];
    }
}
