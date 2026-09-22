def xpath_class_check(cls: str) -> str {
    f"contains(concat(' ',normalize-space(@class),' '),' {cls} ')"
}