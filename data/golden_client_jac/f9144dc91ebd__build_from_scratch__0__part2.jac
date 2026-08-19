def country_code(name: str) -> str {
    m = {"usa": "US", "canada": "CA", "japan": "JP", "brazil": "BR"};
    return m.get(name, "??");
}

with entry {
    for x in ["usa", "japan", "france", "brazil"] {
        print(country_code(x));
    }
}
