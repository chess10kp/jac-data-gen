"""
Examples
--------

>>> snake_to_kebab('donut_eat_animals')
'donut-eat-animals'

"""
def snake_to_kebab(text: str) -> str {
    return text.replace("_", "-");
}