"""Iterate through a count dictionary and print values in a user-friendly way."""
def print_nicely(counts: dict[str, dict[str, int]]) {
    print("pdb id\tarticles\treviews");
    for entry_id in counts.keys() {
        print("%s\t%i\t%i" % (entry_id, counts[entry_id]["articles"], counts[entry_id]["reviews"]));
    }
    return None;
}