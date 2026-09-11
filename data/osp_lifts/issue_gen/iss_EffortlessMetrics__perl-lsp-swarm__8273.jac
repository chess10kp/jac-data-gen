"""EffortlessMetrics/perl-lsp-swarm#8273 -- strict indexed position."""

node Line {
    has idx: int;
    has text: str;
}

edge Next {}

obj PositionMapper {
    has encoding: str;
    has gen: int = 0;
    has lines: list[Line] = [];
}

walker LineWalk {
    has claimed: dict[str, bool] = {};
    has out: list[Line] = [];
    can step with Line entry {
        k = here.idx.__str__();
        if k in self.claimed { skip; }
        self.claimed[k] = True;
        self.out.append(here);
        visit [->:Next:->][?:Line];
    }
}

def PositionMapper_create(encoding: str) -> PositionMapper {
    if encoding != "utf-8" and encoding != "utf-16" { raise ValueError("encoding must be utf-8 or utf-16"); }
    return PositionMapper(encoding=encoding);
}

def add_line(mapper: PositionMapper, text: str) -> None {
    ln = Line(idx=mapper.lines.__len__(), text=text);
    root ++> ln;
    if mapper.lines.__len__() > 0 {
        prev = mapper.lines[mapper.lines.__len__() - 1];
        prev +>:Next:+> ln;
    }
    mapper.lines.append(ln);
    mapper.gen += 1;
}

def total_bytes(mapper: PositionMapper) -> int {
    total = 0;
    for ln in mapper.lines { total += ln.text.__len__() + 1; }
    if total > 0 { total -= 1; }
    return total;
}

def line_col_to_offset(mapper: PositionMapper, line: int, col: int, encoding: str | None) -> int | None {
    enc = mapper.encoding;
    if encoding is not None { enc = encoding; }
    if line < 0 or line >= mapper.lines.__len__() { return None; }
    txt = mapper.lines[line].text;
    max_col = txt.__len__();
    # encoding check simplified ascii
    if col < 0 or col > max_col { return None; }
    base = 0;
    for i in range(line) { base += mapper.lines[i].text.__len__() + 1; }
    return base + col;
}

def offset_to_line_col(mapper: PositionMapper, offset: int) -> tuple[int, int] | None {
    if offset < 0 or offset > total_bytes(mapper) { return None; }
    base = 0;
    for i in range(mapper.lines.__len__()) {
        nxt = base + mapper.lines[i].text.__len__() + 1;
        if offset >= base and offset < nxt {
            return (i, offset - base);
        }
        base = nxt;
    }
    return None;
}

def is_valid_boundary(mapper: PositionMapper, line: int, col: int, encoding: str | None) -> bool {
    return line_col_to_offset(mapper, line, col, encoding) is not None;
}

def mapper_generation(mapper: PositionMapper) -> int {
    return mapper.gen;
}
