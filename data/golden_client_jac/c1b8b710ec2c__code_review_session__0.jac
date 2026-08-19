obj MyObject {
    has data: str;

    def process() -> str {
        return self.data;
    }
}

test "object processing returns the data" {
    my_obj = MyObject(data="test");
    assert my_obj.process() == "test";
}

test "object processing handles empty data" {
    empty = MyObject(data="");
    assert empty.process() == "";
}
