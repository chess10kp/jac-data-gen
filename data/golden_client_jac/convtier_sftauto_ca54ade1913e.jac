def get_capital(country: Any) -> object {
    capitals = {
        'United States': 'Washington, D.C.',
        'Canada': 'Ottawa',
        'United Kingdom': 'London',
        'Australia': 'Canberra'
    };
    return capitals.get(country, 'Unknown');
}



with entry {
    print(get_capital('hello'));
}
