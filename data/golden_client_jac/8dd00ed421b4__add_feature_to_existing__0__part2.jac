import from byllm.lib { Image, Model }

glob llm = Model(model_name="gpt-4o");

obj Person {
    has full_name: str;
    has description: str;
    has year_of_birth: int;
    has nationality: str | None = None;
}

sem Person.description = "Short biography";
sem Person.nationality = "Nationality if identifiable, otherwise null";

def get_person_info(img: Image) -> Person by llm();
sem get_person_info = "Extract person information from the image.";
