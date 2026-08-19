obj NodeRef {
    has value: int = 0;

    def set_value(v: int) -> Self {  # Self as return type
        self.value = v;
        return self;
    }
}
