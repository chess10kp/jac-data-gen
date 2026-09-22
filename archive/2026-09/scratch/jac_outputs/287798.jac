"""Recursively find numbers in JSON data except dicts with "red" value."""
def find_numbers(data: int | list | dict) -> list[int] {
    if isinstance(data, int) {
        return [data];
    }
    numbers = [];
    if isinstance(data, list) {
        for dat in data {
            numbers.extend(find_numbers(dat));
        }
    } elif isinstance(data, dict) {
        if "red" not in data.values() {
            for key in data {
                if isinstance(key, int) {
                    numbers.append(key);
                }
                numbers.extend(find_numbers(data[key]));
            }
        }
    }
    return numbers;
}