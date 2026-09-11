"""cryolithic/AE2RecursivePatternPrinter#16 — PatternAnalyzer recursive dependency resolution."""

from __future__ import annotations


class PatternNetwork:
    # Recipes keyed by item id; parent/ingredient adjacency for crafting deps.
    def __init__(self) -> None:
        self._recipes: dict[str, list[str]] = {}
        self._has_pattern: set[str] = set()


def load_network(
    recipes: dict[str, list[str]],
    existing_patterns: list[str] | None = None,
) -> PatternNetwork:
    net = PatternNetwork()
    for item, ingredients in recipes.items():
        net._recipes[item] = list(ingredients)
        for ing in ingredients:
            net._recipes.setdefault(ing, net._recipes.get(ing, []))
    if existing_patterns:
        net._has_pattern.update(existing_patterns)
    return net


def analyze_pattern(
    store: PatternNetwork,
    root_inputs: list[str],
) -> list[str]:
    # Depth-first dependency resolution with visited guard against cycles.
    results: list[str] = []
    visited: set[str] = set()

    def recurse(item: str) -> None:
        if item in visited:
            return
        visited.add(item)
        if item in store._has_pattern:
            return
        ingredients = store._recipes.get(item)
        if ingredients is None:
            return
        for ing in ingredients:
            recurse(ing)
        results.append(item)

    for inp in root_inputs:
        recurse(inp)
    return results


def missing_recipes(store: PatternNetwork, items: list[str]) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    for item in items:
        if item not in store._recipes and item not in seen:
            seen.add(item)
            out.append(item)
    return sorted(out)
