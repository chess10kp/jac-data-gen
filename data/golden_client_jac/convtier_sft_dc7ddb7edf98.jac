node Slip { has text: str; }

walker Locator {
    has want: str;
    has idx: int = 0;
    has found_at: int = -1;
    can scan with Slip entry {
        if here.text == self.want { self.found_at = self.idx; disengage; }
        self.idx += 1;
        visit [-->];
    }
}

def word_position(spec: dict) -> int {
    words: list = list(spec["words"]);
    if len(words) == 0 { return -1; }
    slips: dict = {};
    pos: int = 0;
    for wd in words { slips[pos] = Slip(text=str(wd)); pos += 1; }
    for j in range(1, len(words)) { slips[j - 1] ++> slips[j]; }
    w = Locator(want=str(spec["target"])) spawn slips[0];
    return w.found_at;
}

with entry {
    print(word_position({'words': ['red', 'blue', 'green', 'blue'], 'target': 'blue'}));
}
