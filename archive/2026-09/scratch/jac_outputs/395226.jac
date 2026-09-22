"""Format account into printable format: name, description and country."""
def format_data(account: dict[str, str]) -> str {
    name = account["name"];
    description = account["description"];
    country = account["country"];
    return f"{name}, a {description}, from {country}";
}