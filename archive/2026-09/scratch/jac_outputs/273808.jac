"""
    KlipChop func to to convert lines into a CSV list
    """
def main(textlines: Callable[[], Iterable[str]], messagefunc: Callable[[str], None], config: dict[str, bool | str]) -> str {
    result = list();
    count = 0;
    for line in textlines() {
        if line not in result {
            result.append(line);
            count += 1;
        }
    }
    if config['sort'] {
        result = sorted(result);
    }
    csv_result = (config['separator'] as str).join(result);
    messagefunc(f'{count} unique lines converted into long CSV list.');
    return csv_result;
}