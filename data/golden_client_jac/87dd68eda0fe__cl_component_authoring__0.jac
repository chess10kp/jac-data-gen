"""chartkit — the one place chart chrome comes from.
Recharts accepts "var(--x)" strings for stroke/fill (they resolve in the CSS
cascade), so every color here is a theme token and charts re-skin with the
ThemeSwitcher for free. Replaces the MONO/_tick/HUES/COLORS/STROKES globs that
were copy-pasted across MonoChart, MultiLineChart, Train, and Results.
"""

glob MONO: str = "var(--font-mono)";

# Module-internal: globs don't survive the JS module boundary — consumers use
# chartColors()/chartColor(i)/gridStroke()/axisStroke().
glob CHART_COLORS: list[str] = [
    "var(--chart-1)", "var(--chart-2)", "var(--chart-3)",
    "var(--chart-4)", "var(--chart-5)", "var(--chart-6)"
];

def:pub chartColors() -> list[str] {
    return CHART_COLORS;
}

def:pub gridStroke() -> str {
    return "var(--border)";
}

def:pub axisStroke() -> str {
    return "var(--input)";
}

"""Axis tick style."""
def:pub tick() -> dict {
    return {"fill": "var(--label)", "fontSize": 10, "fontFamily": MONO};
}

"""Tooltip props: spread as contentStyle/labelStyle/itemStyle/cursor."""
def:pub tipContentStyle() -> dict {
    return {
        "background": "var(--popover)", "border": "1px solid var(--input)",
        "borderRadius": 0, "fontFamily": MONO, "fontSize": 11
    };
}

def:pub tipLabelStyle() -> dict {
    return {"color": "var(--muted-foreground)"};
}

def:pub tipItemStyle() -> dict {
    return {"color": "var(--foreground)"};
}

def:pub tipCursor() -> dict {
    return {"stroke": "var(--input)", "strokeDasharray": "3 3"};
}

"""Nth chart color (wraps)."""
def:pub chartColor(i: int) -> str {
    return CHART_COLORS[i % len(CHART_COLORS)];
}
