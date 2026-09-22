import datetime;

"""Try strftime. In case of failure, return an empty string"""
def try_strftime(x: datetime.date | datetime.datetime, *args: str, **kwargs: str) -> str {
    try {
        return x.strftime(*args, **kwargs);
    } except Exception {
        return '';
    }
}