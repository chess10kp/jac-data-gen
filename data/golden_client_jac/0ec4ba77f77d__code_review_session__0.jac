obj Counter {
    has count: int = 0;
    def inc -> None { self.count += 1; }
    def get -> int  { return self.count; }
}

glob make_counter = lambda start: int -> Counter : Counter(count=start);

with entry {
    c = make_counter(10);
    c.inc(); c.inc(); c.inc();
    print(c.get());   # 13
}
