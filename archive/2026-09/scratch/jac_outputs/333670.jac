"""Filler to list/array."""
def fill(instance: list[int | str | float | bool | None] | dict[int, int | str | float | bool | None], index: int, content: int | str | float | bool | None) {
    if isinstance(instance, list) {
        instance_len = len(instance);
        if instance_len == index or instance_len > index {
            instance[index] = content;
        }
        if instance_len == index - 1 {
            instance.append(content);
        }
        if instance_len < index {
            _n = index - instance_len;
            for _n_ in range(_n + 1) {
                instance.append(None);
            }
            instance[index] = content;
        }
        return;
    }
    if isinstance(instance, dict) {
        instance[index] = content;
        return;
    }
    raise TypeError("Instance need to be list");
}