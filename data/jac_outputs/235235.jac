"""Takes an article and returns the first 25 words. If the article is less than 25 words it returns the full original article."""
def cut_article(article: str) -> str {
    words = article.split(' ');
    if len(words) > 25 {
        return " ".join(words[0:25]);
    }
    return article;
}