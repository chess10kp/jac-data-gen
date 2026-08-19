impl create_piece(kind: PieceKind, color: Color, row: int, col: int) -> Piece {
    pos = (row, col);
    constructors: dict[PieceKind, type[Piece]] = {
        PieceKind.PAWN: Pawn,
        PieceKind.KNIGHT: Knight,
        PieceKind.BISHOP: Bishop,
        PieceKind.ROOK: Rook,
        PieceKind.QUEEN: Queen,
        PieceKind.KING: King
    };
    return constructors[kind](color=color, kind=kind, pos=pos);
}
