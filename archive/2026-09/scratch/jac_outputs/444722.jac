"""Agreement score between two dependency structures."""
def compute_agreement_score(
    arcs1: list[tuple[int, int, str]],
    arcs2: list[tuple[int, int, str]],
    method: str,
    average: bool
) -> float {
    assert len(arcs1) == len(arcs2);
    if method == "joint" {
        shared_arcs = set(arcs1) & set(arcs2);
        score = float(len(shared_arcs));
    } elif method == "independent" {
        score = 0.0;
        dep2head1 = {d: (h, r) for (h, d, r) in arcs1};
        dep2head2 = {d: (h, r) for (h, d, r) in arcs2};
        for dep in dep2head1.keys() {
            (head1, rel1) = dep2head1[dep];
            (head2, rel2) = dep2head2[dep];
            if head1 == head2 {
                score += 0.5;
                if rel1 == rel2 {
                    score += 0.5;
                }
            }
        }
    } else {
        raise Exception("Never occur.");
    }
    if average {
        score = float(score) / len(arcs1);
    }
    return score;
}