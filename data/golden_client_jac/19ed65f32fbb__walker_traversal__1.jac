import from http { HTTPMethod }

@restspec(method=HTTPMethod.GET)
walker :pub get_users {
    can fetch with Root entry {
        report [];
    }
}
