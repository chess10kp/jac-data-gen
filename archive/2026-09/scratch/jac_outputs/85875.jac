"""Update default addition_info with inputs."""
def _update_addition_info(addition_info: dict[str, int] | None) -> dict[str, int] {
    add_info = {"epoch": 0, "batch": 0, "batch_size": 0};
    if not addition_info {
        return add_info;
    } elif not isinstance(addition_info, dict) {
        raise TypeError(
            "The type of 'addition_info' should be 'dict', " "but got '{}'.".format(
                str(type(addition_info))
            )
        );
    } else {
        for (item, value) in addition_info.items() {
            if item not in ("epoch", "batch", "batch_size") {
                raise ValueError(
                    "The key of 'addition_info' should be one of the "
                    "['epoch', 'batch', 'batch_size'], but got '{}'.".format(
                        str(item)
                    )
                );
            }
            if not isinstance(value, int) {
                raise ValueError(
                    "The value of 'addition_info' should be 'int', "
                    "but got '{}'.".format(
                        str(type(value))
                    )
                );
            }
            add_info[item] = value;
        }
        return add_info;
    }
}