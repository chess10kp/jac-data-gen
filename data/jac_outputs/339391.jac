"""Get gnome repo url of package."""
def __get_gnome_url(pkg_info: dict[str, str]) -> str {
    src_repos = pkg_info["src_repo"].split("/");
    if len(src_repos) == 1 {
        url = "https://gitlab.gnome.org/GNOME/" + pkg_info["src_repo"] + ".git";
    } else {
        url = "https://gitlab.gnome.org/" + pkg_info["src_repo"] + ".git";
    }
    return url;
}