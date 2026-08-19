def find_positions(string: Any) -> object {
    words = string.split();
    positions = [];
    for i in range(len(words)) {
        if (words[i].lower() == "is") {
            if (
                ((i == 0) or not words[(i - 1)][-1].isalpha())
                and ((i == (len(words) - 1)) or not words[(i + 1)][0].isalpha())
            ) {
                positions.append(sum((len(words[j]) + 1) for j in range(i)));
            }
        }
    }
    return positions;
}



with entry {
    print(find_positions('hello'));
}
