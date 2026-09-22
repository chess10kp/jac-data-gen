"""Small lexer-aware Jac source transformations used by generation tools."""
from __future__ import annotations

_IDENT_START = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"
_IDENT_CONT = _IDENT_START + "0123456789"


def _is_ident_start(char: str) -> bool:
    return bool(char) and char in _IDENT_START


def _is_ident_cont(char: str) -> bool:
    return bool(char) and char in _IDENT_CONT


def _skip_quoted(source: str, start: int) -> int:
    """Return the first index after the quoted string at ``start``."""
    quote = source[start]
    triple = source.startswith(quote * 3, start)
    width = 3 if triple else 1
    i = start + width
    while i < len(source):
        if source[i] == "\\":
            i += 2
            continue
        if source.startswith(quote * width, i):
            return i + width
        i += 1
    raise ValueError("unterminated string while scanning Jac source")


def _skip_comment(source: str, start: int) -> int:
    end = source.find("\n", start)
    return len(source) if end < 0 else end


def _skip_space(source: str, start: int) -> int:
    i = start
    while i < len(source) and source[i].isspace():
        i += 1
    return i


def _read_identifier(source: str, start: int) -> tuple[str, int]:
    i = start + 1
    while i < len(source) and _is_ident_cont(source[i]):
        i += 1
    return source[start:i], i


def _matching_brace(source: str, opening: int) -> int:
    """Return the index after the brace matching ``opening``."""
    depth = 1
    i = opening + 1
    while i < len(source):
        char = source[i]
        if char in "'\"":
            i = _skip_quoted(source, i)
            continue
        if char == "#":
            i = _skip_comment(source, i)
            continue
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    raise ValueError("unmatched `with entry {` while scanning Jac source")


def _blank_span(source: str, start: int, end: int) -> str:
    """Replace non-newline characters so source line numbers stay stable."""
    return "".join(char if char in "\r\n" else " " for char in source[start:end])


def strip_top_level_with_entry(source: str) -> tuple[str, bool]:
    """Blank one plain top-level ``with entry { ... }`` block.

    The scan understands quoted strings, triple-quoted strings, ``#`` line
    comments, and nested braces. It deliberately does not match ``can with
    entry`` abilities or ``with entry:__main__`` forms. The returned source
    preserves line count and the boolean reports whether a block was found.

    Raises ``ValueError`` for malformed strings/braces or multiple matching
    top-level entry blocks, rather than accidentally executing an entry block.
    """
    spans: list[tuple[int, int]] = []
    depth = 0
    i = 0
    while i < len(source):
        char = source[i]
        if char in "'\"":
            i = _skip_quoted(source, i)
            continue
        if char == "#":
            i = _skip_comment(source, i)
            continue
        if _is_ident_start(char):
            word, end = _read_identifier(source, i)
            if depth == 0 and word == "with":
                entry_start = _skip_space(source, end)
                if source.startswith("entry", entry_start):
                    after_entry = entry_start + len("entry")
                    if (after_entry == len(source)
                            or not _is_ident_cont(source[after_entry])):
                        opening = _skip_space(source, after_entry)
                        if opening < len(source) and source[opening] == "{":
                            close = _matching_brace(source, opening)
                            spans.append((i, close))
                            i = close
                            continue
            i = end
            continue
        if char == "{":
            depth += 1
        elif char == "}":
            if depth == 0:
                raise ValueError("unmatched `}` while scanning Jac source")
            depth -= 1
        i += 1

    if len(spans) > 1:
        raise ValueError("multiple top-level `with entry` blocks")
    if not spans:
        return source, False
    start, end = spans[0]
    return source[:start] + _blank_span(source, start, end) + source[end:], True
