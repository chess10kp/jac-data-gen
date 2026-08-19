node Bead { has val: int; }

walker LowSeek {
    has lo: int;
    can seek with Bead entry {
        if here.val < self.lo { self.lo = here.val; }
        visit [-->];
    }
}

walker HighSeek {
    has hi: int;
    can seek with Bead entry {
        if here.val > self.hi { self.hi = here.val; }
        visit [-->];
    }
}

def min_max_product(spec: dict) -> int {
    nums: list = list(spec["nums"]);
    if not nums { return 0; }
    beads: list = [Bead(val=int(v)) for v in nums];
    for (a, b) in zip(beads, beads[1:]) { a ++> b; }
    low = beads[0] spawn LowSeek(lo=int(nums[0]));
    high = beads[0] spawn HighSeek(hi=int(nums[0]));
    return low.lo * high.hi;
}

with entry {
    print(min_max_product({'nums': [3, 8, 2]}));
}
