obj Builder {
    has value: int = 0;
    def add(n: int) -> Builder {
        self.value += n;
        return self;
    }
    def double() -> Builder {
        self.value *= 2;
        return self;
    }
}
def example() -> Builder {
    result = Builder() .> add(5) .> double();
    return result;
}
