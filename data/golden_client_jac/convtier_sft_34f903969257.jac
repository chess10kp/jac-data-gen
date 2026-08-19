obj Bucket {
    has capacity: int = 3;
    has tokens: int = 3;
    has last: int = 0;

    def allow(t: int) -> bool {
        self.tokens = min(self.capacity, self.tokens + (t - self.last));
        self.last = t;
        if self.tokens > 0 {
            self.tokens -= 1;
            return True;
        }
        return False;
    }
}

def token_bucket(times: list) -> list {
    b = Bucket();
    return [b.allow(t) for t in times];
}

with entry {
    print(token_bucket([0, 0, 0, 0, 5]));
}
