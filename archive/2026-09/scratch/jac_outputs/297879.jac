"""
    KlipChop func to to convert text into unique lines
    """
def main(textlines: Any, messagefunc: Any, config: Any) -> object {
    result = `list();
    count = 0;
    for line in textlines() {
        if (line not in result) {
            result.append(line);
            count += 1;
        }
    }
    if config['sort'] {
        result = sorted(result);
    }
    result = '\n'.join(result);
    messagefunc(f'{count} unique lines');
    return result;
}