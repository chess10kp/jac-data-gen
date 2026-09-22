"""Convert a list of split ASCII text lines into traces (a list of lists of floats)."""
def lines_into_traces(lines: list[list[str]]) -> list[list[float]] {
    traces = [];
    num_of_traces = len(lines[0]);
    for i in range(num_of_traces) {
        traces.append([]);
    }
    for line in lines {
        for i in range(num_of_traces) {
            try {
                traces[i].append(float(line[i]));
            } except Exception as e {
                continue;
            }
        }
    }
    return traces;
}