"""Convert new-style method names with underscores to old style camel-case names."""
def underscore_to_camelcase(name: str) -> str {
    name[0].lower() + name.replace('_', ' ').title().replace(' ', '')[1:]
}