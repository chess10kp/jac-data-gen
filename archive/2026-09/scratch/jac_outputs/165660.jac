"""
The API is actually terribly unreliable at providing information on
whether an entity is human or corporate. What is consistent is that
companies are provided in UPPER CASE and humans provided in the format
"SURNAME, Othernames". This takes advantage of this to identify if a
record is human.
"""
def human_check(string: str) -> str {
    for i in string {
        if i.islower() {
            return "Individual";
        }
    }
    return "Corporate";
}