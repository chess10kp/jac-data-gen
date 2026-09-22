"""Removes underscores from dictionary"""
def desanitise(dic: dict[str, str]) -> dict[str, str] {
    return {key[1:]: value for (key, value) in dic.items()};
}