impl create_piece(kind: PieceKind, color: Color, row: int, col: int) -> Piece {
    pos = (row, col);
    match kind {
        case PieceKind.PAWN: return Pawn(color=color, kind=kind, pos=pos);
        case PieceKind.KNIGHT: return Knight(color=color, kind=kind, pos=pos);
        case PieceKind.BISHOP: return Bishop(color=color, kind=kind, pos=pos);
        case PieceKind.ROOK: return Rook(color=color, kind=kind, pos=pos);
        case PieceKind.QUEEN: return Queen(color=color, kind=kind, pos=pos);
        case _: return King(color=color, kind=kind, pos=pos);
    }
}
