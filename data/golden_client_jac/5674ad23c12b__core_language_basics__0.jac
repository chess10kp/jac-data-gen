obj Counter {
    static has count: int = 0;

    # Static method -- no self or cls, pure utility
    static def get_count() -> int {
        return Counter.count;
    }

    # Static factory -- explicit class name keeps the return type clean
    static def make() -> Counter {
        return Counter();
    }

    # Instance method -- self is the instance
    def increment() -> None {
        Counter.count += 1;
    }
}
