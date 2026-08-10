"""Compare two ages; return 0 on match or within 2 years, else -1."""
def age_similarity_scorer(age_1: object, age_2: object) -> int {
    a1: int;
    a2: int;
    try {
        a1 = int(age_1);
    } except Exception {
        return 0;
    }
    try {
        a2 = int(age_2);
    } except Exception {
        return 0;
    }
    if abs(a1 - a2) <= 2 {
        return 0;
    }
    return -1;
}