"""Creates a number of full and half stars according to the given rating."""
def starify_rating(rating: Any) -> object {
    rate = 0;
    try {
        rate = float(rating.split('/')[0]);
    } except ValueError {
        print('Could not parse recipe rating: ', rating);
    }
    full = ''.join(('\uf005' * int(rate)));
    half = '\uf089' if (rate != int(rate)) else '';
    return '<font face="FontAwesome">{}{}</font>'.format(full, half);
}