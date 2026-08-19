enum PieceKind { PAWN = 0, KNIGHT = 1, BISHOP = 2, ROOK = 3, QUEEN = 4, KING = 5 }

glob WHITE_SYMBOLS: dict[PieceKind, str] = {
    PieceKind.PAWN: "P", PieceKind.KNIGHT: "N", PieceKind.BISHOP: "B",
    PieceKind.ROOK: "R", PieceKind.QUEEN: "Q", PieceKind.KING: "K"
};

glob BLACK_SYMBOLS: dict[PieceKind, str] = {
    PieceKind.PAWN: "p", PieceKind.KNIGHT: "n", PieceKind.BISHOP: "b",
    PieceKind.ROOK: "r", PieceKind.QUEEN: "q", PieceKind.KING: "k"
};

glob PIECE_VALUES: dict[PieceKind, int] = {
    PieceKind.PAWN: 100, PieceKind.KNIGHT: 320, PieceKind.BISHOP: 330,
    PieceKind.ROOK: 500, PieceKind.QUEEN: 900, PieceKind.KING: 20000
};
