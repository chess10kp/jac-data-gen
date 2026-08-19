obj Example {
    has field: int = 0;  # Instance variable (with 'has')

    def method() {
        local = 5;  # Local variable (no 'has')
        self.field = local;
    }
}
