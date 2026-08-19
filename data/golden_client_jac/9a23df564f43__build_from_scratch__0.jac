def do_processing(input: str) -> list {
    return [input, input + "_processed"];
}

walker:priv ProcessAndSummarize {
    has input: str;

    can process with Root entry {
        results = do_processing(self.input);
        report results;
        report {"count": len(results), "status": "complete"};
    }
}

with entry {
    result = root spawn ProcessAndSummarize(input="data");
}
