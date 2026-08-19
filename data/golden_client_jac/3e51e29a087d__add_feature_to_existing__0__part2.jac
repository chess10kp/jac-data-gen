"""ESTree AST Node Definitions for ECMAScript."""

obj Node {}

obj Position {
    has line: int = 0,
        column: int = 0;
}

obj Identifier(Node) {
    has name: str = '',
        `type: str = 'Identifier';
}

obj ArrayExpression(Node) {
    has elements: list = [],
        `type: str = 'ArrayExpression';
}
