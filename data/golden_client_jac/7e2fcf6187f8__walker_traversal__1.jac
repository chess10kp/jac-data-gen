# Bad: Manual dict construction loses type information
walker:priv BadCreate {
    has name: str;

    can create with Root entry {
        item = here ++> Item(name=self.name);
        report {"name": item[0].name, "data": item[0].data};  # Don't do this
    }
}

# Good: Report the typed object directly
walker:priv GoodCreate {
    has name: str;

    can create with Root entry {
        item = here ++> Item(name=self.name);
        report item[0];  # The runtime handles serialization automatically
    }
}
