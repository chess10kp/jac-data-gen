"""Normalize the value of all element in a collection
each element will be divided by the sum"""
def normalize(collection: list[int] | dict[str, int]) -> list[float] | dict[str, float] {
    if isinstance(collection, dict) {
        total = 0;
        result: dict[str, float] = {};
        for key in collection {
            total += collection[key];
        }
        if total == 0 {
            return {};
        }
        for key in collection {
            result[key] = collection[key] / total;
        }
    } else {
        total = sum(collection);
        result: list[float] = [0.0] * len(collection);
        if total == 0 {
            return result;
        }
        for i in range(len(collection)) {
            result[i] = collection[i] / total;
        }
    }
    return result;
}