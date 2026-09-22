"""Finds any listings that are listed as having different assessments."""
def find_mismatches(
    listings: list[dict[str, str]],
    assessments: dict[str, list[str]],
    accuracy: float = 0.01
) -> list[dict[str, str | list[str] | None]] {
    mismatches = [];
    for l in listings {
        if l["title"] in assessments {
            article_assessments = assessments[l["title"]];
            processed_assessments = list(
                map(
                    str.lower,
                    filter(lambda (c: str) { c != ''; }, article_assessments)
                )
            );
            if len(processed_assessments) != 0 {
                assessment_ratio = (
                    processed_assessments.count(l["assessment"].lower())
                    / len(processed_assessments)
                );
                if assessment_ratio < accuracy {
                    mismatches.append(
                        {
                            "title": l["title"],
                            "listed_as": l["assessment"],
                            "current": article_assessments
                        }
                    );
                }
            }
        } else {
            mismatches.append(
                {"title": l["title"], "listed_as": l["assessment"], "current": None}
            );
        }
    }
    return mismatches;
}