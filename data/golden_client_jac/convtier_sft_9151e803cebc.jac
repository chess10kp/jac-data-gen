obj Playlist {
    has tracks: list[str] = [];

    def add(track: str) -> None { self.tracks.append(track); }

    def length() -> int { return len(self.tracks); }
}

with entry {
    p = Playlist();
    p.add("x");
    p.add("y");
    print(p.length());
}
