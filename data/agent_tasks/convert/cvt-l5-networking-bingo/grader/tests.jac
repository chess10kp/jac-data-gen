# Hidden tests for the networking-bingo port (in-process walker spawns). The store persists
# between tests, so every test uses fresh random user ids / discord handles and checks deltas.
import uuid;
import from main { UserModel, Attribute, BingoBoard, hc, add_or_get_user, get_attr, set_attr,
                   get_bingo_board, new_bingo_board, add_bingo }

def first(rs: list[any]) -> any {
    assert len(rs) > 0;
    return rs[0];
}

def fresh_id -> int {
    return 1000000 + uuid.uuid4().int % 900000000;
}

def grid -> list[list[int]] {
    return [[r * 5 + c + 1 for c in range(5)] for r in range(5)];
}

def board_of(uid: int) -> dict[str, any] {
    return dict(first((root spawn get_bingo_board(user_id=uid)).reports));
}

test "health check" {
    assert first((root spawn hc()).reports) == "server is running";
}

test "user ids are issued sequentially and reused for a known user" {
    tag = uuid.uuid4().hex[:8];
    a = dict(first((root spawn add_or_get_user(name="kim", discord="kim#" + tag)).reports));
    assert a["ok"] == True;
    b = dict(first((root spawn add_or_get_user(name="lee", discord="lee#" + tag)).reports));
    assert b["user_id"] == a["user_id"] + 1;
    again = dict(first((root spawn add_or_get_user(name="kim", discord="kim#" + tag)).reports));
    assert again["ok"] == True and again["user_id"] == a["user_id"];
    assert len([u for u in [root -->[?:UserModel]] if u.discord == "kim#" + tag]) == 1;
}

test "attributes: missing, set once, duplicate rejected" {
    uid = fresh_id();
    miss = dict(first((root spawn get_attr(user_id=uid)).reports));
    assert miss["ok"] == False and miss["message"] == "특성 없음. 추가 필요.";
    ok = dict(first((root spawn set_attr(user_id=uid, attribute=[3, 7, 11])).reports));
    assert ok["ok"] == True and ok["message"] == "특성 추가 완료";
    got = dict(first((root spawn get_attr(user_id=uid)).reports));
    assert got["ok"] == True and list(got["attribute"]) == [3, 7, 11];
    dup = dict(first((root spawn set_attr(user_id=uid, attribute=[1])).reports));
    assert dup["ok"] == False and dup["message"] == "특성이 이미 있습니다.";
    assert list(dict(first((root spawn get_attr(user_id=uid)).reports))["attribute"]) == [3, 7, 11];
}

test "boards: missing, create once, duplicate rejected" {
    uid = fresh_id();
    miss = board_of(uid);
    assert miss["ok"] == False and miss["message"] == "빙고보드 없음, 갱신 필요";
    ok = dict(first((root spawn new_bingo_board(user_id=uid, board=grid())).reports));
    assert ok["ok"] == True and ok["message"] == "빙고보드가 추가 완료";
    b = board_of(uid);
    assert b["ok"] == True and [list(r) for r in b["board"]] == grid() and len(b["gave_ids"]) == 0;
    dup = dict(first((root spawn new_bingo_board(user_id=uid, board=[[0]])).reports));
    assert dup["ok"] == False and dup["message"] == "빙고보드가 이미 존재합니다";
    assert len([x for x in [root -->[?:BingoBoard]] if x.user_id == uid]) == 1;
}

test "add bingo marks the giver's attribute cells" {
    uid = fresh_id();
    gid = fresh_id();
    g = grid();
    g[2][3] = 1500;
    root spawn new_bingo_board(user_id=uid, board=g);
    root spawn set_attr(user_id=gid, attribute=[0, 6, 13, 24]);
    r = dict(first((root spawn add_bingo(user_id=uid, gave_id=gid)).reports));
    assert r["ok"] == True and r["message"] == "빙고보드가 갱신 완료";
    b = board_of(uid);
    rows = [list(x) for x in b["board"]];
    assert rows[0][0] == 1 - 1000 and rows[1][1] == 7 - 1000 and rows[4][4] == 25 - 1000;
    assert rows[2][3] == 1500;
    assert rows[0][1] == 2 and rows[3][3] == 19 and rows[3][2] == 18;
    assert list(b["gave_ids"]) == [gid];
}

test "repeat bingo keeps the Python behaviour" {
    uid = fresh_id();
    gid = fresh_id();
    root spawn new_bingo_board(user_id=uid, board=grid());
    root spawn set_attr(user_id=gid, attribute=[12]);
    root spawn add_bingo(user_id=uid, gave_id=gid);
    root spawn add_bingo(user_id=uid, gave_id=gid);
    b = board_of(uid);
    assert [list(x) for x in b["board"]][2][2] == 13 - 2000;
    assert list(b["gave_ids"]) == [gid, gid];
}

test "giver without attributes and unknown board" {
    uid = fresh_id();
    root spawn new_bingo_board(user_id=uid, board=grid());
    nobody = fresh_id();
    r = dict(first((root spawn add_bingo(user_id=uid, gave_id=nobody)).reports));
    assert r["ok"] == True;
    b = board_of(uid);
    assert [list(x) for x in b["board"]] == grid() and list(b["gave_ids"]) == [nobody];
    lost = dict(first((root spawn add_bingo(user_id=fresh_id(), gave_id=nobody)).reports));
    assert lost["ok"] == False and lost["message"] == "해당 유저의 빙고보드를 찾을 수 없습니다";
}
