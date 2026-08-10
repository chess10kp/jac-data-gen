"""
        Get url of JSON file for an experiment, give it's ID number
    """
def make_url_given_id(expid: int) -> str {
    return "https://neuroinformatics.nl/HBP/allen-connectivity-viewer/json/streamlines_{}.json.gz".format(expid);
}