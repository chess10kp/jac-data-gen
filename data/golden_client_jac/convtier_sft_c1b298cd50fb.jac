node Plot { has idx: int; has crop: int; has taken: bool = False; }

walker BestSeek {
    has best_idx: int = -1;
    has best_val: int = 0;
    can scan with Plot entry {
        if not here.taken {
            if self.best_idx == -1 or here.crop > self.best_val {
                self.best_idx = here.idx;
                self.best_val = here.crop;
            }
        }
        visit [-->];
    }
}

walker Claim {
    has idx: int;
    has grabbed: int = 0;
    can grab with Plot entry {
        if here.idx == self.idx {
            here.taken = True;
            self.grabbed = here.crop;
        } else {
            visit [-->];
        }
    }
}

def top_k_harvest(spec: dict) -> int {
    nums: list = list(spec["nums"]);
    if not nums { return 0; }
    plots: list = [];
    for i in range(len(nums)) { plots.append(Plot(idx=i, crop=int(nums[i]))); }
    for (a, b) in zip(plots, plots[1:]) { a ++> b; }
    total: int = 0;
    rounds: int = 0;
    while rounds < int(spec["k"]) {
        seek = plots[0] spawn BestSeek();
        if seek.best_idx == -1 { break; }
        claim = plots[0] spawn Claim(idx=seek.best_idx);
        total += claim.grabbed;
        rounds += 1;
    }
    return total;
}

with entry {
    print(top_k_harvest({'nums': [4, 9, 2, 7], 'k': 2}));
}
