import from http { HTTPMethod }

@restspec(method=HTTPMethod.GET, path="/custom/users")
walker :pub list_users {
    can fetch with `root entry {
        report [];
    }
}
