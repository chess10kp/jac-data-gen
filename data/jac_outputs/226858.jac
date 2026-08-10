"""Parse a competitors object from Bovada and return the home and away teams, respectively"""
def parse_teams(competitors: list[dict[str, bool | str]]) -> tuple[str, str] {
    if len(competitors) > 2 {
        raise Exception("Unexpected objects in competitors");
    }
    home_team = "";
    away_team = "";
    for team in competitors {
        if team["home"] {
            home_team = team["name"] as str;
        } else {
            away_team = team["name"] as str;
        }
    }
    if home_team != "" or away_team == "" {
        return (home_team.upper(), away_team.upper());
    }
    raise Exception("Competitors was not properly parsed. Missing data.");
}