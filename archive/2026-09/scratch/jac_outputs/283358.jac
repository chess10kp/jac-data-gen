"""Extract the rating histogram from embedded Javascript code."""
def extract_ratings(txt: str | list[str]) -> dict[int, int] | None {
    codelines = "".join(txt).split(";");
    rating_code = [
        line.strip()
        for line in codelines
        if "renderRatingGraph" in line
    ];
    if not rating_code {
        return None;
    }
    rating_line = rating_code[0];
    rating_array = rating_line[(rating_line.index("[") + 1):rating_line.index("]")];
    ratings = {(5 - i): int(x) for (i, x) in enumerate(rating_array.split(","))};
    return ratings;
}