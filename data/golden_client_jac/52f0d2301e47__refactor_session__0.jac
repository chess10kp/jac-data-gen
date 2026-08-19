"""RL driver (synthetic): run-length encode a string as char+count pairs."""

def run_length_encode(s: str) -> str;

impl run_length_encode {
    # >>>HOLE id="syn_run_length_encode" instruction="Implement run_length_encode(s): return a run-length encoding where each maximal run of one repeated character is emitted as the character immediately followed by its run length as digits (e.g. 'aaab' -> 'a3b1'). Return the empty string for empty input."
    if len(s) == 0 {
        return "";
    }
    result = "";
    prev = s[0];
    count = 1;
    for c in s[1:] {
        if c == prev {
            count += 1;
        } else {
            result += f"{prev}{count}";
            prev = c;
            count = 1;
        }
    }
    result += f"{prev}{count}";
    return result;
    # <<<HOLE
}

with entry {
    for x in ["aaab", "abc", "wwwww", "aabbaa"] {
        print(run_length_encode(x));
    }
}
