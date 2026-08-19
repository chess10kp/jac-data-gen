import from byllm.lib { Image }

enum Personality { INTROVERT, EXTROVERT }
sem Personality.INTROVERT = "Person who is shy and reticent";
sem Personality.EXTROVERT = "Person who is outgoing and socially confident";

obj Person {
    has full_name: str;
    has personality: Personality;
    has year_of_death: int | None = None;
}

"""Extract person information from the image."""
def get_person_info(img: Image) -> Person by llm();
