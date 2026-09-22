"""Minimum remaining length for sequential, parallel cut detection."""
def get_min_remaining_length(traces: list[list[str]]) -> tuple[list[int], list[int]] {
    min_len_traces: list[int] = [];
    min_rem_length: list[int] = [];
    for x in traces {
        if len(x) == 0 {
            min_len_traces.append(0);
        } else {
            min_len_traces.append(len(x[0]));
        }
        min_rem_length.append(0);
    }
    min_rem_length[-1] = 0;
    min_rem_length[-2] = min_len_traces[-1];
    j = len(traces) - 3;
    while j >= 0 {
        min_rem_length[j] = min_rem_length[j + 1] + min_len_traces[j + 1];
        j -= 1;
    }
    return (min_len_traces, min_rem_length);
}