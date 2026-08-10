"""The sum of all numbers except from maps with a "red" property."""
def sum_non_red(`obj: int | str | list[int | str | list | dict] | dict[str, int | str | list | dict]) -> int {
    if isinstance(`obj, int) {
        return `obj;
    }
    if isinstance(`obj, str) {
        return 0;
    }
    if isinstance(`obj, list) {
        return sum(map(sum_non_red, `obj));
    }
    if isinstance(`obj, dict) {
        if 'red' in `obj.values() {
            return 0;
        }
        return sum(map(sum_non_red, `obj.values()));
    }
    raise TypeError('Unexpected type: {}'.format(type(`obj)));
}