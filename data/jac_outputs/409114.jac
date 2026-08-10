"""
    #returns array of the indices in uctext where the letters of ucterm were found.
    # EG: subsequenceMatch("nothing", "ni") returns [0, 4]. subsequenceMatch("nothing", "a")
    # returns null.
	#simple subsequence match
	"""
def subsequenceMatch(uctext: str, ucterm: str) -> list[int] | None {
    hits = [];
    texti = -1;
    termi = 0;
    while termi < len(ucterm) {
        texti = uctext.find(ucterm[termi], texti + 1);
        if texti == -1 {
            return None;
        }
        hits.append(texti);
        termi += 1;
    }
    return hits;
}