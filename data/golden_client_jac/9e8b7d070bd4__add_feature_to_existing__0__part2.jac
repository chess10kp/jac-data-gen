# This is a line comment

#* This is a
   block comment *#

"""Return the app's tagline."""
def tagline() -> str {
    return "Plan smart, live better.";
}

with entry {
    # Print the tagline
    print(tagline());
}
