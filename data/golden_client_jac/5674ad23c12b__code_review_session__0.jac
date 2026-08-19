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

    # Static -- increments the shared class-level count, uses no instance state
    static def increment() -> None {
        Counter.count += 1;
    }
}
