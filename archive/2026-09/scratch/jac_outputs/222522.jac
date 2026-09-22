"""
    Checked. Returns the hemisphere of the most common timezones or raises an exception if we haven't figured out the hemisphere.
    some of the Southern TZs are right on the equator
    broadly the division is: South America + Australia = southern list
    Europe, USA, Canada, Mexico = Northern List
    exception is Caracas, which is in South America but is in the Northern hemisphere.
    Some of the Brazilian TZs are quite close to the equator, as is America/Guayaquil. So in general Northern tzs are farther North
    than Southern TZs are South.
    """
def get_hemisphere_of_timezone(tz: str) -> str {
    northern_timezones = [
        'Europe/Berlin',
        'Europe/Lisbon',
        'Europe/Paris',
        'Europe/Rome',
        'Europe/London',
        'Europe/Copenhagen',
        'America/Denver',
        'Europe/Moscow',
        'America/Chicago',
        'Europe/Madrid',
        'America/Los_Angeles',
        'America/New_York',
        'America/Vancouver',
        'America/Toronto',
        'America/Mexico_City',
        'America/Caracas'
    ];
    southern_timezones = [
        'America/Buenos_Aires',
        'Australia/Melbourne',
        'Australia/Sydney',
        'America/Lima',
        'America/Recife',
        'America/Santiago',
        'America/Fortaleza',
        'America/Sao_Paulo',
        'America/Guayaquil'
    ];
    if tz in northern_timezones {
        return 'Northern';
    }
    if tz in southern_timezones {
        return 'Southern';
    }
    raise Exception("Not a valid timezone");
}