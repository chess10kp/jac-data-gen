import random
import string
from datetime import datetime, date, time, timedelta
from typing import Union


TIME_FORMAT = "%H:%M"
DATE_FORMAT = "%Y-%m-%d"


def is_time_right_format(time_string: str) -> bool:
    try:
        t = datetime.strptime(time_string, TIME_FORMAT).time()

        # This filters out situation when user passed one number as minutes, like `16:0` or `09:5`.
        # Minutes must contain 2 digits.
        if len(time_string.split(":")[1]) != 2:
            return False

        # Time has to be between `05:00` and `19:55`.
        if t.hour < 5 or t.hour > 19:
            return False

        # Minutes must be divisible by 5.
        return t.minute % 5 == 0
    except ValueError:
        return False


def dt_time_min(dt: Union[datetime, date]) -> datetime:
    """
    Converts any datetime/date to new datetime with same date and time=0:00:00
    """
    return datetime.combine(dt, time.min)


def dt_time_max(dt: Union[datetime, date]) -> datetime:
    """
    Converts any datetime/date to new datetime with same date and time=23:59:59.999999
    """
    return datetime.combine(dt, time.max)


def subtract_days_from_datetime(input_datetime: datetime, days_to_subtract: int) -> datetime:
    """
    Returns a new datetime that is the specified number of days earlier.
    """
    return input_datetime - timedelta(days=days_to_subtract)


def get_dates_between(start_date: datetime, end_date: datetime) -> list[date]:
    """
    Get a list of all dates between the given start and end datetimes, inclusive.
    """
    return [(start_date + timedelta(days=i)).date() for i in range((end_date - start_date).days + 1)]


def generate_notification_time() -> str:
    """
    Generate appropriate `notification_time` for `Medication` objects tests.
    """
    first_hour_digit = random.randint(0, 1)

    # Available options for 0: 05, 06, 07, 08, 09
    # Available options for 1: 10, 11, 12, 13, 14, 15, 16, 17, 18, 19
    second_hour_digit = random.randint(5 if first_hour_digit == 0 else 0, 9)

    minute_digit = random.randint(0, 5)

    return f"{first_hour_digit}{second_hour_digit}:{minute_digit}5"


def generate_random_string(a: int = 5, b: int = 20) -> str:
    return ''.join(random.choices(string.ascii_lowercase + string.digits, k=random.randint(a, b)))
