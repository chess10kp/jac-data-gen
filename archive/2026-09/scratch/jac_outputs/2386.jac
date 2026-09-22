"""Reorganize texts into tuples of combined signs and translations."""
def reorganize_data(texts: list[list[tuple[str, str]]]) -> list[tuple[list[str], list[str]]] {
    data = [];
    for sentence in texts {
        signs = [];
        trans = [];
        for (sign, tran) in sentence {
            signs.append(sign);
            trans.append(tran);
        }
        data.append((signs, trans));
    }
    return data;
}