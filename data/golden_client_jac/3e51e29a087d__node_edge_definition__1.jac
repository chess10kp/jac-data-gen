"""ESTree AST Node Definitions for ECMAScript."""

obj SourceLocation {
    has source: (str | None) = None,
        start: (Position | None) = None,
        end: (Position | None) = None;
}

obj Position {
    has line: int = 0,
        column: int = 0;
}

obj Identifier(Node) {
    has name: str = '',
        `type: TypingLiteral['Identifier'] = 'Identifier';
}

# ... 60+ more node types
