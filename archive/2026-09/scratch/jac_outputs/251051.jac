"""Function to count words from title occuring inside the article body"""
def count(article: list[str]) -> float {
    number_of_words = 0;
    heading = article[0].split();
    for word in heading {
        if word in article[1] {
            number_of_words += 1;
        }
    }
    return number_of_words / len(heading);
}