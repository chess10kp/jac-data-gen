"""Return the serendipity of a RNA."""
def get_serendipity_val(dic: dict[object, float], key: object) -> float {
    try {
        return dic[key];
    } except KeyError {
        return 1.0;
    }
}