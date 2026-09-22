obj Cockpit {
    has _optimizer_name: str = "";
}

"""Split the logpath to identify test problem, data set, etc."""
def _extract_problem_info(source: str | Cockpit) -> dict[str, str] {
    if isinstance(source, str) {
        try {
            dicty = {
                "logpath": source + ".json",
                "optimizer": source.split("/")[-3],
                "testproblem": source.split("/")[-4],
                "dataset": source.split("/")[-4].split("_", 1)[0],
                "model": source.split("/")[-4].split("_", 1)[1]
            };
        } except Exception {
            dicty = {
                "logpath": source + ".json",
                "optimizer": "",
                "testproblem": "",
                "dataset": "",
                "model": ""
            };
        }
    } else {
        dicty = {
            "logpath": "",
            "optimizer": source._optimizer_name,
            "testproblem": "",
            "dataset": "",
            "model": ""
        };
    }
    return dicty;
}