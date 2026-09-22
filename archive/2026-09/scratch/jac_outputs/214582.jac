"""Returns a list of pilot alpha codes corresponding to the input word."""
def to_pilot_alpha(word: str) -> list[str] {
    pilot_alpha = [
        'Alfa',
        'Bravo',
        'Charlie',
        'Delta',
        'Echo',
        'Foxtrot',
        'Golf',
        'Hotel',
        'India',
        'Juliett',
        'Kilo',
        'Lima',
        'Mike',
        'November',
        'Oscar',
        'Papa',
        'Quebec',
        'Romeo',
        'Sierra',
        'Tango',
        'Uniform',
        'Victor',
        'Whiskey',
        'Xray',
        'Yankee',
        'Zulu'
    ];
    word = word.upper();
    return [pilot_alpha[ord(c) - 65] for c in word];
}