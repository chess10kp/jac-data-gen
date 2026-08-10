"""An operation as a dictionary."""
def operation_dict(ts_epoch: Any, request_dict: Any) -> object {
    return {
        "model": request_dict,
        "model_type": "Request",
        "args": [request_dict["id"]],
        "kwargs": {"extra": "kwargs"},
        "target_garden_name": "child",
        "source_garden_name": "parent",
        "operation_type": "REQUEST_CREATE"
    };
}