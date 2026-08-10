"""preprocess formatting of the list of ingredients

will remove string 'and' and '&' if present"""
def prep_ingr(ingredients: list[str]) -> list[str] {
    result = [];
    for ingr in ingredients {
        if "and" in ingr or "&" in ingr {
            cleaned = ingr.replace("and", "").replace("&", "");
            parts = cleaned.split(" ");
            while "" in parts {
                parts.remove("");
            }
            for part in parts {
                result.append(part);
            }
        } else {
            result.append("_".join(ingr.split(" ")));
        }
    }
    return result;
}