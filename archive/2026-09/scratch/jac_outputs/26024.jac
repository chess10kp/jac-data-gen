"""Gets device release date."""
def get_release_date(data: dict[str, str]) -> int | None {
    try {
        launch = data['launch'];
        splt = launch.split(' ');
        return int(float(splt[0]));
    } except (KeyError, TypeError) {
        return None;
    }
}