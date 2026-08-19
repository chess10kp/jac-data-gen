obj Bullet {
    has x: float;
    has y: float;
    has z: float;
    has life: float;
}

obj Target {
    has x: float;
    has y: float;
    has z: float;
    has alive: bool = True;

    def dist2(b: Bullet) -> float {
        return (b.x - self.x) * (b.x - self.x)
             + (b.y - self.y) * (b.y - self.y)
             + (b.z - self.z) * (b.z - self.z);
    }
}

def resolve_hits(world: dict) -> int {
    bullets = [Bullet(x=d["x"], y=d["y"], z=d["z"], life=d["life"]) for d in world["bullets"]];
    targets = [Target(x=d["x"], y=d["y"], z=d["z"]) for d in world["targets"]];
    score = 0;
    for b in bullets {
        if b.life <= 0.0 {
            continue;
        }
        for t in targets {
            if t.alive and t.dist2(b) < 1.4 {
                t.alive = False;
                score += 1;
                break;
            }
        }
    }
    return score;
}

with entry {
    print(resolve_hits({'bullets': [{'x': 0.0, 'y': 1.0, 'z': 0.0, 'life': 1.5}, {'x': 9.0, 'y': 1.0, 'z': 9.0, 'life': 0.0}, {'x': 4.0, 'y': 2.0, 'z': -3.0, 'life': 0.8}], 'targets': [{'x': 0.5, 'y': 1.0, 'z': 0.0}, {'x': 4.0, 'y': 2.5, 'z': -3.0}, {'x': 9.0, 'y': 1.0, 'z': 9.0}]}));
}
