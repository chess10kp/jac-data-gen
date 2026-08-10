"""Given a list of libraries, returns url."""
def unpack_libraries(libraries: list[dict[str, str]]) -> str | None {
    if libraries {
        return libraries[0].get('url');
    }
}