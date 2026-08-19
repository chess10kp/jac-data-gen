"""RL driver (synthetic): count the vowels (a,e,i,o,u) in a string, case-insensitive."""

def vowel_count(s: str) -> int;

impl vowel_count {
    # >>>HOLE id="syn_vowel_count" instruction="Implement vowel_count(s): return the number of characters in s that are vowels ('a','e','i','o','u'), comparing case-insensitively (lowercase each character before testing)."
    count = 0;
    for c in s.lower() {
        if c in "aeiou" {
            count += 1;
        }
    }
    return count;
    # <<<HOLE
}

with entry {
    for x in ["Hello", "AEIOU", "xyz", "Programming"] {
        print(vowel_count(x));
    }
}
