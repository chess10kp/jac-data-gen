"""turn the word_counts into a list of triplets w, p(w | spam) and p(w| ~spam)"""
def word_probabilities(
    counts: Any, total_spams: Any, total_non_spams: Any, k: Any = 0.5
) -> object {
    return [
        (
            w,
            ((spam + k) / (total_spams + (2 * k))),
            ((non_spam + k) / (total_non_spams + (2 * k)))
        ) for (w, (spam, non_spam)) in counts.items()
    ];
}