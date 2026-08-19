import from math { pi }

obj Circle {
    has radius: float = 1.0;
    def area -> float;
}

obj Display {
    has label: str = "";
    def render -> str;
}

impl Circle.area -> float {
    return pi * self.radius * self.radius;
}

impl Display.render -> str {
    return "Displaying: " + self.label;
}
