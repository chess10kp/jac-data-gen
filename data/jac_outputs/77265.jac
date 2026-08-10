"""Simple way to compress string."""
def simple_compression(string: str) -> str {
    compressed_string = "";
    (last, n) = ("", 1);
    for cha in string {
        if cha == last {
            n += 1;
        } else {
            if n > 1 {
                compressed_string += str(n);
            }
            compressed_string += cha;
            (last, n) = (cha, 1);
        }
    }
    if n > 1 {
        compressed_string += str(n);
    }
    return compressed_string;
}