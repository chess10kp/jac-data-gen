"""
    Takes two-dimensional array and looks through each collumn to find the highest odd for each outcome:
    [
        [5, 7.7,  1.2],
        [4, 6.25, 1.6]
    ]

    would produce

    ([5, 7.7, 1.6],
     [0, 0,   1])
    """
def find_best_odds(books: Any) -> object {
    if (len(books) < 2) {
        raise ValueError("Must contain at least two bookers odds.");
    }
    best = [0] * len(books[0]);
    book_id = [0] * len(books[0]);
    for id in range(len(books)) {
        bookie = books[id];
        for i in range(len(bookie)) {
            if (bookie[i] > best[i]) {
                best[i] = bookie[i];
                book_id[i] = id;
            }
        }
    }
    return (best, book_id);
}