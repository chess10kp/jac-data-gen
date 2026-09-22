"""
    KlipChop func to to convert CSV into seperate lines
    """
def main(textlines: Any, messagefunc: Any, config: Any) -> object {
    result = `list();
    count = 0;
    for line in textlines() {
        if (line not in result) {
            result.extend(line.split(config['separator']));
            count += 1;
        }
    }
    if config['sort'] {
        result = sorted(result);
    }
    count = len(result);
    result = '\n'.join(result);
    messagefunc(f'Text converted into {count} lines.');
    return result;
}