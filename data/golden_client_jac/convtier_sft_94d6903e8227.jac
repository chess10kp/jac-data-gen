node Camera {}
node Xform { has kind: str; has vx: float; has vy: float; has vz: float; }

walker ApplyChain {
    has x: float, y: float, z: float;
    can start with Camera entry { visit [-->]; }
    can step with Xform entry {
        if here.kind == "translate" {
            self.x += here.vx;
            self.y += here.vy;
            self.z += here.vz;
        } else {
            self.x *= here.vx;
            self.y *= here.vy;
            self.z *= here.vz;
        }
        visit [-->];
    }
}

def transform_point(spec: dict) -> list {
    cam = Camera();
    prev = cam;
    for op in spec["ops"] {
        nxt = Xform(kind=str(op["kind"]), vx=float(op["v"][0]), vy=float(op["v"][1]), vz=float(op["v"][2]));
        prev ++> nxt;
        prev = nxt;
    }
    w = cam spawn ApplyChain(x=float(spec["point"][0]), y=float(spec["point"][1]), z=float(spec["point"][2]));
    return [round(w.x, 6), round(w.y, 6), round(w.z, 6)];
}

with entry {
    print(transform_point({'point': [1.0, 2.0, 3.0], 'ops': [{'kind': 'translate', 'v': [1.0, 1.0, 0.5]}, {'kind': 'scale', 'v': [2.0, 1.0, 2.0]}]}));
}
