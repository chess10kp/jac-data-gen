node Arena {}
node Bullet { has x: int, v: int; }
node Target { has cell: int, score: int; }

walker HitScan {
    has shots: list = [], marks: list = [], total: int = 0;
    can start with Arena entry { visit [-->]; }
    can trace with Bullet entry { self.shots.append((here.x, here.x + here.v)); }
    can sight with Target entry { self.marks.append((here.cell, here.score)); }
    can tally with exit {
        for (cell, score) in self.marks {
            hit = False;
            for (lo, hi) in self.shots {
                if lo <= cell and cell <= hi { hit = True; }
            }
            if hit { self.total += score; }
        }
    }
}

def hit_score(spec: dict) -> int {
    arena = Arena();
    for b in spec["bullets"] { arena ++> Bullet(x=int(b["x"]), v=int(b["v"])); }
    for t in spec["targets"] { arena ++> Target(cell=int(t["cell"]), score=int(t["score"])); }
    return (arena spawn HitScan()).total;
}

with entry {
    print(hit_score({'bullets': [{'x': 0, 'v': 5}, {'x': 10, 'v': 2}], 'targets': [{'cell': 3, 'score': 10}, {'cell': 11, 'score': 25}, {'cell': 20, 'score': 100}]}));
}
