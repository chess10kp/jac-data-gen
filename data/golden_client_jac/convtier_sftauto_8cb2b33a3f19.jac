def get_capital(country_code: Any) -> object {
    capitals = {'US': 'Washington, D.C.', 'CA': 'Ottawa', 'GB': 'London'};
    return capitals.get(country_code, capitals['GB']);
}



with entry {
    print(get_capital('hello'));
}
