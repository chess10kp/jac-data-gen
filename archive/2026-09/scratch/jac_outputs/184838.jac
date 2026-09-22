glob PER_MILLION = 1_000_000.0;

"""Simple maths method for finding relative frequency of a word in the
focus corpus compared to the reference corpus. Frequencies are
calculated per million and N is the smoothing parameter (default N = 1)."""
def smoothed_relative_freq(
    n_focus: int,
    n_ref: int,
    size_focus: int,
    size_ref: int,
    N: int = 1
) -> float {
    f_focus = n_focus * PER_MILLION / size_focus;
    f_ref = n_ref * PER_MILLION / size_ref;
    return (f_focus + N) / (f_ref + N);
}