node Post { has score: int; }

walker PeakSeek {
    has best: int;
    can scan with Post entry {
        if here.score > self.best { self.best = here.score; }
        visit [-->];
    }
}

walker PeakCount {
    has target: int;
    has hits: int = 0;
    can tally with Post entry {
        if here.score == self.target { self.hits += 1; }
        visit [-->];
    }
}

def count_max_occurrences(spec: dict) -> int {
    nums: list = list(spec["nums"]);
    if not nums { return 0; }
    posts: list = [Post(score=int(v)) for v in nums];
    for (a, b) in zip(posts, posts[1:]) { a ++> b; }
    seeker = posts[0] spawn PeakSeek(best=int(nums[0]));
    return (posts[0] spawn PeakCount(target=seeker.best)).hits;
}

with entry {
    print(count_max_occurrences({'nums': [3, 7, 7, 2]}));
}
