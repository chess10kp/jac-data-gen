"""Networking-bingo API (port of Pseudo-Lab/PseudoTown `api/`).

ODMantic collections -> nodes on root: `UserId` (the id counter), `UserModel`,
`Attribute` (a member's chosen traits = bingo cell numbers) and `BingoBoard`.
FastAPI handlers -> public walkers with the same names; the `{"ok": ...}` result
dicts are reported unchanged (messages kept verbatim, in Korean).
"""

glob BOARD_XY: int = 5,
     MAGIC_NUM: int = 1000;

node UserId {
    has user_id: int;
}

node UserModel {
    has user_id: int;
    has name: str;
    has discord: str;
}

node Attribute {
    has user_id: int;
    has attribute: list[int];
}

node BingoBoard {
    has user_id: int;
    has gave_ids: list[int] = [];
    has board: list[list[int]] = [];
}

def find_attr(user_id: int) -> Attribute | None {
    for a in [root -->[?:Attribute]] {
        if a.user_id == user_id {
            return a;
        }
    }
    return None;
}

def find_board(user_id: int) -> BingoBoard | None {
    for b in [root -->[?:BingoBoard]] {
        if b.user_id == user_id {
            return b;
        }
    }
    return None;
}

"""UserId.issue_id: a single counter node, 1 on first use, then +1 each time."""
def issue_id -> int {
    counters = [c for c in [root -->[?:UserId]]];
    if not counters {
        root ++> UserId(user_id=1);
        return 1;
    }
    counters[0].user_id = counters[0].user_id + 1;
    return counters[0].user_id;
}

"""GET /hc"""
walker:pub hc {
    can ping with Root entry {
        report "server is running";
    }
}

"""POST /auth/user/{name}"""
walker:pub add_or_get_user {
    has name: str;
    has discord: str;

    can register with Root entry {
        for u in [here -->[?:UserModel]] {
            if u.name == self.name and u.discord == self.discord {
                report {"ok": True, "user_id": u.user_id};
                return;
            }
        }
        uid = issue_id();
        here ++> UserModel(user_id=uid, name=self.name, discord=self.discord);
        report {"ok": True, "user_id": uid};
    }
}

"""GET /bingo/attr/{user_id}"""
walker:pub get_attr {
    has user_id: int;

    can fetch with Root entry {
        a = find_attr(self.user_id);
        if a is None {
            report {"ok": False, "message": "특성 없음. 추가 필요."};
        } else {
            report {"ok": True, "attribute": list(a.attribute)};
        }
    }
}

"""POST /bingo/attr/{user_id}"""
walker:pub set_attr {
    has user_id: int;
    has attribute: list[int];

    can store with Root entry {
        if find_attr(self.user_id) {
            report {"ok": False, "message": "특성이 이미 있습니다."};
            return;
        }
        here ++> Attribute(user_id=self.user_id, attribute=self.attribute);
        report {"ok": True, "message": "특성 추가 완료"};
    }
}

"""GET /bingo/{user_id}"""
walker:pub get_bingo_board {
    has user_id: int;

    can fetch with Root entry {
        b = find_board(self.user_id);
        if b is None {
            report {"ok": False, "message": "빙고보드 없음, 갱신 필요"};
        } else {
            report {"ok": True, "board": [list(row) for row in b.board], "gave_ids": list(b.gave_ids)};
        }
    }
}

"""POST /bingo/{user_id}"""
walker:pub new_bingo_board {
    has user_id: int;
    has board: list[list[int]];

    can create with Root entry {
        if find_board(self.user_id) {
            report {"ok": False, "message": "빙고보드가 이미 존재합니다"};
            return;
        }
        here ++> BingoBoard(user_id=self.user_id, gave_ids=[], board=self.board);
        report {"ok": True, "message": "빙고보드가 추가 완료"};
    }
}

"""POST /bingo/{user_id}/add -- `gave_id` met `user_id`: mark every cell numbered by
one of gave_id's attributes (cell n is row n // 5, column n % 5) by subtracting
MAGIC_NUM, exactly like the Python (including its quirks)."""
walker:pub add_bingo {
    has user_id: int;
    has gave_id: int;

    can mark with Root entry {
        b = find_board(self.user_id);
        if b is None {
            report {"ok": False, "message": "해당 유저의 빙고보드를 찾을 수 없습니다"};
            return;
        }
        a = find_attr(self.gave_id);
        board = [list(row) for row in b.board];
        for num in (list(a.attribute) if a else []) {
            x = num % BOARD_XY;
            y = int(num / BOARD_XY);
            if board[y][x] < MAGIC_NUM {
                board[y][x] -= MAGIC_NUM;
            }
        }
        b.board = board;
        if self.user_id not in b.gave_ids {
            b.gave_ids = list(b.gave_ids) + [self.gave_id];
        }
        report {"ok": True, "message": "빙고보드가 갱신 완료"};
    }
}
