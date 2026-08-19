obj Scoreboard {
    has best: int = 0;

    def submit(score: int) -> None {
        if score > self.best { self.best = score; }
    }
}

with entry {
    sb = Scoreboard();
    sb.submit(10);
    sb.submit(30);
    sb.submit(20);
    print(sb.best);
}
