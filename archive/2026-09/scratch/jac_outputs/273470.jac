"""
Assigning political party label from president lastname. Taken from:
https://en.wikipedia.org/wiki/List_of_presidents_of_the_United_States
Using "?" to represent parties before 1964.
"""
def party_from_president(name: str, year: int) -> str {
    if year < 1964 {
        return "?";
    }
    d = {
        "Trump": "R",
        "Obama": "D",
        "Bush": "R",
        "Clinton": "D",
        "Reagan": "R",
        "Carter": "D",
        "Ford": "R",
        "Nixon": "R",
        "Johnson": "D"
    };
    return d[name];
}