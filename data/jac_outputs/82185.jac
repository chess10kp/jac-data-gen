"""For fiches which have no question, add them without qas."""
def format_context_as_squad(fiche_id: str, context: str) -> dict[str, str | list[dict[str, str]]] {
    {"title": fiche_id, "paragraphs": [{"context": context}]}
}