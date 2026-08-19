obj QueryBuilder {
    has table: str = "",
        limit_val: int = -1;

    def from_table(table: str) -> Self {
        self.table = table;
        return self;
    }

    def limit(n: int) -> Self {
        self.limit_val = n;
        return self;
    }
}

with entry {
    q = QueryBuilder().from_table("users").limit(10);
}
