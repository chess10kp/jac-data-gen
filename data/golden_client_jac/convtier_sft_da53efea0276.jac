node Arena {}
node Target { has x: float; has y: float; has z: float; has alive: bool = True; }
node Bullet {
    has px: float; has py: float; has pz: float;
    has vx: float; has vy: float; has vz: float;
    has life: float;
}

walker ResolveHits {
    has step: float, r2: float;
    has targets: list = [], score: int = 0;
    can start with Arena entry { visit [-->][?:Bullet]; }
    can fly with Bullet entry {
        if here.life > 0.0 {
            here.px += here.vx * self.step;
            here.py += here.vy * self.step;
            here.pz += here.vz * self.step;
            here.life -= self.step;
            hit = False;
            for t in self.targets {
                if t.alive and not hit {
                    dx = here.px - t.x;
                    dy = here.py - t.y;
                    dz = here.pz - t.z;
                    if dx * dx + dy * dy + dz * dz < self.r2 {
                        t.alive = False;
                        here.life = 0.0;
                        self.score += 1;
                        hit = True;
                    }
                }
            }
        }
    }
}

def score_tally(spec: dict) -> int {
    arena = Arena();
    tnodes: list = [];
    for t in spec["targets"] {
        tn = Target(x=float(t[0]), y=float(t[1]), z=float(t[2]));
        arena ++> tn;
        tnodes.append(tn);
    }
    for b in spec["bullets"] {
        arena ++> Bullet(px=float(b["pos"][0]), py=float(b["pos"][1]), pz=float(b["pos"][2]),
                         vx=float(b["vel"][0]), vy=float(b["vel"][1]), vz=float(b["vel"][2]),
                         life=float(b["life"]));
    }
    w = arena spawn ResolveHits(step=float(spec["step"]), r2=float(spec["r2"]), targets=tnodes);
    return w.score;
}

with entry {
    print(score_tally({'bullets': [{'pos': [0.0, 0.0, 0.0], 'vel': [2.0, 0.0, 0.0], 'life': 1.0}, {'pos': [5.0, 0.0, 0.0], 'vel': [0.0, 0.0, 0.0], 'life': 0.0}, {'pos': [0.0, 0.0, 4.0], 'vel': [0.0, 0.0, -2.0], 'life': 1.0}], 'targets': [[1.0, 0.0, 0.0], [0.0, 0.0, 3.0]], 'step': 0.5, 'r2': 1.4}));
}
