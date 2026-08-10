def decode_position(s: str) -> int {
    return int(
        s.replace("K", "000")
            .replace("k", "000")
            .replace("M", "000000")
            .replace("m", "000000")
    );
}