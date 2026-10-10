"""Shelter adoptions: Pet nodes on root, Adopter nodes linked by Adopted edges."""

node Pet {
    has name: str;
    has species: str;
    has age_years: int = 0;
    has status: str = "available";

    def view -> dict[str, any] {
        return {"id": jid(self), "name": self.name, "species": self.species,
                "age_years": self.age_years, "status": self.status};
    }
}

node Adopter {
    has name: str;
}

edge Adopted: Adopter --> Pet {}

walker:pub add_pet {
    has name: str;
    has species: str;
    has age_years: int = 0;

    can add with Root entry {
        if not self.name.strip() or self.age_years < 0 {
            report {"error": "name required and age must be >= 0"};
            return;
        }
        p = here ++> Pet(name=self.name.strip(), species=self.species.strip().lower(), age_years=self.age_years);
        report p.view();
    }
}

walker:pub list_available {
    has species: str = "";
    has found: list[Pet] = [];

    can start with Root entry {
        visit [here -->[?:Pet]];
    }

    can look with Pet entry {
        if here.status == "available" and (not self.species or here.species == self.species.strip().lower()) {
            self.found.append(here);
        }
    }

    can finish with exit {
        ordered = sorted(self.found, key=lambda (p: Pet) -> tuple[int, str] { return (p.age_years, p.name); });
        report [p.view() for p in ordered];
    }
}

walker:pub adopt {
    has pet_id: str;
    has adopter: str;

    can take with Root entry {
        pets = [p for p in [here -->[?:Pet]] if jid(p) == self.pet_id];
        if not pets {
            report {"error": "no such pet"};
            return;
        }
        pet = pets[0];
        if pet.status != "available" {
            report {"error": "pet already adopted"};
            return;
        }
        people = [a for a in [here -->[?:Adopter]] if a.name == self.adopter];
        person = people[0] if people else here ++> Adopter(name=self.adopter);
        person +>:Adopted:+> pet;
        pet.status = "adopted";
        report pet.view();
    }
}

walker:pub adopter_pets {
    has adopter: str;

    can history with Root entry {
        pets: list[Pet] = [];
        for a in [here -->[?:Adopter]] {
            if a.name == self.adopter {
                pets = [p for p in [a ->:Adopted:->]];
            }
        }
        report [p.view() for p in sorted(pets, key=lambda (p: Pet) -> str { return p.name; })];
    }
}
