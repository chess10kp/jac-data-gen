import from byllm.lib { Model }

glob llm = Model(model_name="gpt-4o");

obj Education {
    has degree: str;
    has institution: str;
    has year: int;
}

obj Experience {
    has title: str;
    has company: str;
    has years: int;
    has description: str;
}

obj Resume {
    has name: str;
    has email: str;
    has phone: str | None;
    has skills: list[str];
    has education: list[Education];
    has experience: list[Experience];
    has certifications: list[str] = [];
}

def parse_resume(text: str) -> Resume by llm();
