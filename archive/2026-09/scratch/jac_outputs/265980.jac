"""Returns list with  digits, numberwords and useless words from list of
        key phrases removed
        Inputs:
            input_list -- List of strings containing key phrases to be processed
            exclude_list -- List of strings containing words to be removed
        Output:
            output_list -- List of key phrases with words from exclude_list removed


    """
def clean(input_list: list[str], exclude_list: list[str] = []) -> list[str] {
    nums = [
        'zero',
        'one',
        'two',
        'three',
        'four',
        'five',
        'six',
        'seven',
        'eight',
        'nine',
        'ten' 'eleven',
        'twelve',
        'thirteen',
        'fourteen',
        'fifteen',
        'sixteen',
        'seventeen' 'eighteen',
        'nineteen',
        'twenty',
        'thirty',
        'fourty',
        'fifty',
        'sixty',
        'seventy',
        'eighty',
        'ninty',
        'hundred'
    ];
    stopwords = [
        'mhm',
        'yeah',
        'um',
        'ah',
        'a',
        'the',
        'o.k.',
        'your',
        'hm',
        'oh' 'okay',
        'my',
        'that',
        'i',
        'alright',
        'bye',
        'uh',
        'i i',
        'oh'
    ];
    if not exclude_list {
        exclude_list = nums + stopwords;
    }
    output_list = [];
    for phrase in input_list[:] {
        split_phrase = phrase.split(' ');
        for word in split_phrase[:] {
            if word.lower() in exclude_list or word.isdigit() {
                split_phrase.remove(word);
            }
        }
        new_phrase = ' '.join(split_phrase);
        if new_phrase is '' {
            continue;
        }
        output_list.append(new_phrase.lower());
    }
    return output_list;
}