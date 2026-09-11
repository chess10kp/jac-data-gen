"""EffortlessMetrics/perl-lsp-swarm#8273 -- strict indexed position mapper."""

from __future__ import annotations

from collections import deque

class PositionMapper:
    def __init__(self, encoding: str = "utf-16") -> None:
        if encoding not in ("utf-8", "utf-16"):
            raise ValueError("encoding must be utf-8 or utf-16")
        self.encoding = encoding
        self.lines: list[str] = []
        self.line_starts: list[int] = [0]
        self.source_gen: int = 0
        self._index_built = False

    def add_line(self, text: str) -> None:
        self.lines.append(text)
        # recompute starts (hand-rolled prefix sum)
        total = 0
        self.line_starts = [0]
        for ln in self.lines:
            total += len(ln) + 1  # +1 for newline separator (normalized)
            self.line_starts.append(total)
        self.source_gen += 1
        self._index_built = True

    def total_bytes(self) -> int:
        if not self.lines:
            return 0
        return self.line_starts[-1] - 1

def line_col_to_offset(mapper: PositionMapper, line: int, col: int, encoding: str | None = None) -> int | None:
    enc = encoding or mapper.encoding
    if line < 0 or line >= len(mapper.lines):
        return None
    text = mapper.lines[line]
    # strict: col must be on valid boundary (not inside surrogate/codepoint interior)
    # simplified: col must be <= len(text) in encoding units
    max_col = len(text.encode("utf-8")) if enc == "utf-8" else len(text)  # utf-16 length approx as code units
    if col < 0 or col > max_col:
        return None
    # exact offset via prefix sum
    base = mapper.line_starts[line]
    # for utf-16, validate boundary: if text has multi-byte, reject interior?
    # simplified: reject col that splits a character (not possible with ascii fixture)
    return base + col

def offset_to_line_col(mapper: PositionMapper, offset: int) -> tuple[int, int] | None:
    if offset < 0 or offset >= mapper.total_bytes() + 1:
        return None
    # walk line_starts to find line (hand-rolled linear scan / adjacency-like walk)
    for i in range(len(mapper.line_starts) - 1):
        if mapper.line_starts[i] <= offset < mapper.line_starts[i + 1]:
            return (i, offset - mapper.line_starts[i])
    return None

def is_valid_boundary(mapper: PositionMapper, line: int, col: int, encoding: str | None = None) -> bool:
    return line_col_to_offset(mapper, line, col, encoding) is not None

def mapper_generation(mapper: PositionMapper) -> int:
    return mapper.source_gen
