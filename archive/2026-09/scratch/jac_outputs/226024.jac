"""Get additional information for each event for the markers' info window"""
def get_concert_info(event: dict[str, str | dict | list], location: str) -> dict[str, str] {
    concert = {};
    concert["venue"] = event['_embedded']['venues'][0]['name'];
    concert["location"] = location;
    concert["city"] = event['_embedded']['venues'][0]['city']['name'];
    concert["date"] = event['dates']['start']['localDate'];
    concert["link"] = event["url"];
    return concert;
}