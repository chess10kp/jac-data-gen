obj MyClass {
    has property: str;

    def method {
        print(self.property);
    }
}

with entry {
    my_obj = MyClass(property="Hello, World!");
    my_obj.method();
}
