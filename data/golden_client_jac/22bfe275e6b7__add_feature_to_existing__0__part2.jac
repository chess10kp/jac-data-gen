obj Rectangle {
    has width: float;
    has height: float;
    has area: float by postinit;
    has perimeter: float by postinit;  # New computed field

    def postinit {
        self.area = self.width * self.height;
        self.perimeter = 2 * (self.width + self.height);
    }
}

with entry {
    r = Rectangle(width=4.0, height=3.0);
    print(f"area={r.area}, perimeter={r.perimeter}");
}
