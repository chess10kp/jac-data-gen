"""Check kwargs argument."""
def _kwargs_arg_log(**kwargs: int | bool) -> dict[str, int | bool] {
    taillines = 100;
    timestamps = False;
    if "taillines" in kwargs and kwargs.get("taillines") is not None {
        taillines = kwargs["taillines"];
    }
    if "timestamps" in kwargs and kwargs.get("timestamps") is not None {
        timestamps = kwargs["timestamps"];
    }
    return {"tail_lines": taillines, "timestamps": timestamps};
}