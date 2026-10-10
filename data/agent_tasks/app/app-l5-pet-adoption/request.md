Hi! I volunteer at an animal shelter and we want a simple adoption API we can hook a website up to later. I've created a Jac service project here with `jac create --kind service`. Could you build it?

What it needs to do:
- **Add a pet**: `POST /walker/add_pet` with `name`, `species` (like "cat", "dog", "rabbit" — store lower-case) and `age_years` (int, 0 or more). Report the pet as `{"id", "name", "species", "age_years", "status"}` where status starts as `"available"`.
- **Browse**: `POST /walker/list_available` with an optional `species` filter (empty means all). Report one list of available pets, youngest first, then by name.
- **Adopt**: `POST /walker/adopt` with `pet_id` and `adopter` (a person's name). The pet becomes `"adopted"` and gets linked to an adopter node for that person (create the adopter the first time). Adopting a pet that's already adopted or doesn't exist should report `{"error": "..."}`.
- **Adopter history**: `POST /walker/adopter_pets` with `adopter`. Report the list of pets that person has adopted, sorted by name (empty list for someone we don't know).

Use the pet node's `jid` as its id. Everything should be stored in the graph under root. Please write tests too, and check that `jac run` starts the API.
