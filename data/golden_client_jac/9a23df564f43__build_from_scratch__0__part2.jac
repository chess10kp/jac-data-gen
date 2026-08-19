def do_processing(input: str) -> list {
    return [input, input + "_processed"];
}

walker:priv ProcessAndSummarize {
    has input: str;

    can process with Root entry {
        # First report: raw results
        results = do_processing(self.input);
        report results;

        # Second report: summary
        report {
            "count": len(results),
            "status": "complete"
        };
    }
}

with entry {
    # Usage
    result = root spawn ProcessAndSummarize(input="data");
    raw_results = result.reports[0];  # First report
    summary = result.reports[1];       # Second report
}
