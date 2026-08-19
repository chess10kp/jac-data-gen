def first(items: list) -> any {
    return items[0];
}

# New helper following the same placeholder pattern
def last(items: list) -> any {
    return items[-1];
}

obj Container {
    has value: any;
}

with entry {
    nums = [10, 20, 30];
    print(first(nums));
    print(last(nums));
    box = Container(value="wrapped");
    print(box.value);
}
