"""Filter names in 'namelist', returning those which match 'globpattern'."""
def _globtest(globpattern: str, namelist: list[str]) -> list[str] {
    import re;
    pattern = globpattern.replace(".", r"\.");
    pattern = pattern.replace("*", r".*");
    pattern = pattern.replace("?", r".");
    pattern = '|'.join(pattern.split());
    compiled = re.compile(pattern);
    return list(filter(compiled.match, namelist));
}