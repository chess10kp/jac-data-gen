"""from [1]
    [1]:https://stackoverflow.com/questions/1175208/elegant-python-function-to-convert-camelcase-to-snake-case
    """
def _camel2snake(s: str) -> str {
    "".join([("_" + c.lower()) if c.isupper() else c for c in s]).lstrip("_")
}