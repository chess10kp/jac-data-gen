def simplerep(`obj: object) -> str {
    return "{}(...)".format(`obj.__class__.__name__);
}