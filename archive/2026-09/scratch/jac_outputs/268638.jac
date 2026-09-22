import from datetime { datetime }

def get_hover_string(n_commits: int, dt: datetime | str) -> str {
    match n_commits {
        case 0:
            n_txt = 'No commits on ';
        case 1:
            n_txt = '1 commit on ';
        case _:
            n_txt = f'{n_commits} commits on ';
    }
    if dt == '' {
        return '';
    }
    return n_txt + (dt as datetime).strftime('%b %d, %Y');
}