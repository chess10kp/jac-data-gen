"""Join multiple lists of ingredients with ' , '."""
def join_ingredients(ingredients_listlist: Any) -> object {
    return [' , '.join(i) for i in ingredients_listlist];
}