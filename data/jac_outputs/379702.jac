"""Recursively fetch values from nested JSON."""
def json_extract(`obj: dict[str, list | dict | str | int | float | bool | None] | list[list | dict | str | int | float | bool | None], key: str) -> list[list | dict | str | int | float | bool | None] {
    arr: list[list | dict | str | int | float | bool | None] = [];
    def extract(`obj: dict[str, list | dict | str | int | float | bool | None] | list[list | dict | str | int | float | bool | None], arr: list[list | dict | str | int | float | bool | None], key: str) -> list[list | dict | str | int | float | bool | None] {
        if isinstance(`obj, dict) {
            for (k, v) in `obj.items() {
                if isinstance(v, (dict, list)) {
                    extract(
                        v as dict[str, list | dict | str | int | float | bool | None] | list[list | dict | str | int | float | bool | None],
                        arr,
                        key
                    );
                } elif k == key {
                    arr.append(v);
                }
            }
        } elif isinstance(`obj, list) {
            for item in `obj {
                extract(
                    item as dict[str, list | dict | str | int | float | bool | None] | list[list | dict | str | int | float | bool | None],
                    arr,
                    key
                );
            }
        }
        return arr;
    }
    return extract(`obj, arr, key);
}