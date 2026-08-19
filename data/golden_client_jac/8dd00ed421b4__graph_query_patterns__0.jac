import from byllm.lib { Image }

    obj Person {
        has full_name: str;
        has description: str;
        has year_of_birth: int;
    }

    sem Person.description = "Short biography";

    def get_person_info(img: Image) -> Person by llm();
    sem get_person_info = "Extract person information from the image.";
