obj Data {
    def transform(param: str) -> Data {
        return self;
    }
    def format() -> str {
        return "formatted";
    }
}

def example(item: Data | None, data: Data | None) {
    # Returns None if item is None, doesn't call method
    result = item?.transform("x");

    # Chained with arguments
    output = data?.transform("param")?.format();
}
