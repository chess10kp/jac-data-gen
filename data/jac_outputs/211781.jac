"""Queries the Alexa API for top sites with a global scope."""
def query_api_url(count: int, start: int) -> str {
    return f'https://ats.api.alexa.com/api?Action=Topsites&Count={count}&ResponseGroup=Country&Start={start}&Output=json';
}