"""Jac grammar for tree-sitter (local binding)."""
from tree_sitter import Language, Parser

from .binding import language as _capsule

__all__ = ["LANGUAGE", "new_parser"]


def get_language() -> Language:
    return Language(_capsule())


# Shared immutable language handle.
LANGUAGE = get_language()


def new_parser() -> Parser:
    p = Parser(LANGUAGE)
    return p
