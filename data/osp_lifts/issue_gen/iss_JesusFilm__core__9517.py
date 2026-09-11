"""JesusFilm/core#9517 — cycle-safe cascade-to-fixpoint language availability."""

from __future__ import annotations

from typing import Dict, List, Set, Tuple


class LanguageStore:
    def __init__(self) -> None:
        self._langs: Set[str] = set()
        self._requires: Dict[str, List[str]] = {}
        self._available: Dict[str, bool] = {}

    def add(self, code: str) -> None:
        self._langs.add(code)
        self._requires.setdefault(code, [])
        self._available[code] = True

    def require(self, dst: str, src: str) -> None:
        if dst not in self._langs or src not in self._langs:
            raise KeyError("unknown language")
        if src not in self._requires[dst]:
            self._requires[dst].append(src)

    def recompute_available(self) -> int:
        changed = True
        rounds = 0
        while changed:
            changed = False
            rounds += 1
            for code in sorted(self._langs):
                if not self._available.get(code, False):
                    continue
                for dep in sorted(self._requires.get(code, [])):
                    if not self._available.get(dep, False):
                        self._available[code] = False
                        changed = True
        return rounds

    def available_for(self, code: str) -> bool:
        if code not in self._langs:
            return False
        return bool(self._available.get(code, False))


def load_languages(codes: List[str], requires: List[Tuple[str, str]]) -> LanguageStore:
    s = LanguageStore()
    for c in codes:
        s.add(c)
    for dst, src in requires:
        s.require(dst, src)
    return s
