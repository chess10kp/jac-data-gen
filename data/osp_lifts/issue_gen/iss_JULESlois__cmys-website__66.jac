"""Non-Euclidean maze room-state machine. JULESlois/cmys-website#66."""

glob CARDINALS: list[str] = ["east", "north", "south", "west"];

node Room {
    has room_id: str;
}

edge Door {}

walker BfsWalker {
    has claimed: dict[str, bool] = {};
    has queue: list[dict[str, any]] = [];
    has qi: int = 0;
    has prev: dict[str, str] = {};
    has pdir: dict[str, str] = {};
    has out: list[str] = [];
    has started: bool = False;

    can tick with Room entry {
        if not self.started {
            st = initial_state();
            sk = state_key(st);
            self.claimed[sk] = True;
            self.queue.append(st);
            self.started = True;
        }
        if self.qi >= len(self.queue) {
            print("bfs_fail");
            disengage;
        }
        cur = self.queue[self.qi];
        self.qi += 1;
        if is_solved(cur) {
            self.out = rebuild_path(state_key(cur), self.prev, self.pdir);
            print("bfs_ok=" + str(len(self.out)));
            disengage;
        }
        exs = list_exits(cur);
        for d in exs {
            nxt = step(cur, d);
            nk = state_key(nxt);
            if nk in self.claimed {
                continue;
            }
            self.claimed[nk] = True;
            self.prev[nk] = state_key(cur);
            self.pdir[nk] = d;
            self.queue.append(nxt);
        }
        visit :0: here;
    }
}

walker MazeDemo {
    can boot entry {
        p = shortest_path();
        print("demo_path_len=" + str(len(p)));
        disengage;
    }
}

with entry {
    root spawn MazeDemo;
}

def state_key(st: dict[str, any]) -> str {
    lr = st["lastRoomId"];
    if lr is None {
        lr = "";
    }
    return st["roomId"] + "\x1f" + str(st["phase"]) + "\x1f" + lr + "\x1f" + str(st["marks"]);
}

def initial_state -> dict[str, any] {
    return {
        "roomId": "gate",
        "phase": 0,
        "lastRoomId": "",
        "marks": 0,
        "steps": 0,
    };
}

def transition(
    room_id: str,
    direction: str,
    phase: int,
    last_room_id: str,
    marks: int,
) -> dict[str, any] {
    new_phase = phase;
    new_marks = marks;
    dest = "";
    if room_id == "gate" {
        if direction == "north" {
            dest = "well";
        } elif direction == "east" {
            dest = "clock";
        }
    } elif room_id == "well" {
        if direction == "north" {
            dest = "gate";
        } elif direction == "south" {
            dest = "glass";
        }
    } elif room_id == "glass" {
        if direction == "south" {
            dest = "well";
        } elif direction == "north" and phase >= 1 {
            dest = "fork";
        }
    } elif room_id == "clock" {
        if direction == "south" {
            dest = "rotunda";
        } elif direction == "west" {
            dest = "glass";
            new_phase = (phase + 1) % 3;
        }
    } elif room_id == "rotunda" {
        if phase == 0 {
            if direction == "north" {
                dest = "archive";
            } elif direction == "west" {
                dest = "static";
            }
        } elif phase == 1 {
            if direction == "north" {
                dest = "static";
            } elif direction == "west" {
                dest = "archive";
            }
        } elif phase == 2 {
            if direction == "north" {
                dest = "well";
            } elif direction == "west" {
                dest = "archive";
            }
        }
    } elif room_id == "archive" {
        if direction == "south" {
            dest = "rotunda";
        }
    } elif room_id == "static" {
        if direction == "east" {
            dest = "rotunda";
        }
    } elif room_id == "fork" {
        if direction == "north" {
            if last_room_id == "glass" and phase == 2 {
                dest = "exit";
            } elif last_room_id == "static" {
                dest = "well";
            } else {
                dest = "archive";
            }
        } elif direction == "south" {
            dest = "glass";
        }
    }
    return {"roomId": dest, "phase": new_phase, "marks": new_marks};
}

def list_exits(state: dict[str, any]) -> list[str] {
    out: list[str] = [];
    for d in CARDINALS {
        tr = transition(state["roomId"], d, state["phase"], state["lastRoomId"], state["marks"]);
        if tr["roomId"] != "" {
            out.append(d);
        }
    }
    return sorted(out);
}

def step(state: dict[str, any], direction: str) -> dict[str, any] {
    if direction != "east" and direction != "north" and direction != "south" and direction != "west" {
        raise ValueError("unknown direction");
    }
    tr = transition(state["roomId"], direction, state["phase"], state["lastRoomId"], state["marks"]);
    if tr["roomId"] == "" {
        raise ValueError("blocked");
    }
    return {
        "roomId": tr["roomId"],
        "phase": tr["phase"],
        "lastRoomId": state["roomId"],
        "marks": tr["marks"],
        "steps": state["steps"] + 1,
    };
}

def is_solved(state: dict[str, any]) -> bool {
    return state["roomId"] == "exit";
}

def reverse_list(xs: list[str]) -> list[str] {
    out: list[str] = [];
    i = len(xs) - 1;
    while i >= 0 {
        out.append(xs[i]);
        i -= 1;
    }
    return out;
}

def rebuild_path(end_k: str, prev: dict[str, str], pdir: dict[str, str]) -> list[str] {
    rev: list[str] = [];
    cur_k = end_k;
    for _i in range(64) {
        if cur_k not in prev {
            break;
        }
        rev.append(pdir[cur_k]);
        cur_k = prev[cur_k];
    }
    return reverse_list(rev);
}

def build_graph -> Room {
    graph_root = Room(room_id="__graph__");
    gate = Room(room_id="gate");
    graph_root ++> gate;
    return gate;
}

def shortest_path -> list[str] {
    gate = build_graph();
    w = gate spawn BfsWalker(claimed={});
    return w.out;
}
