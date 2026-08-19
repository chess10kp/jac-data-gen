def welcome():
    """List all available api routes."""
    return (
        f"Available Routes:<br/>"
        f"/api/v1.0/precipitation<br/>"
        f"/api/v1.0/stations"
        f"/api/v1.0/tobs <br>"
        f"/api/v1.0/start_date <br> "
        f"/api/v1.0/end_date <br> "
    )

assert welcome() == (
    "Available Routes:<br/>"
    f"/api/v1.0/precipitation<br/>"
    f"/api/v1.0/stations"
    f"/api/v1.0/tobs <br>"
    f"/api/v1.0/start_date <br> "
    f"/api/v1.0/end_date <br> "
)
assert welcome( ) == (
    f"Available Routes:<br/>"
    f"/api/v1.0/precipitation<br/>"
    f"/api/v1.0/stations"
    f"/api/v1.0/tobs <br>"
    f"/api/v1.0/start_date <br> "
    f"/api/v1.0/end_date <br> "
    )
assert welcome() == (
        f"Available Routes:<br/>"
        f"/api/v1.0/precipitation<br/>"
        f"/api/v1.0/stations"
        f"/api/v1.0/tobs <br>"
        f"/api/v1.0/start_date <br> "
        f"/api/v1.0/end_date <br> "
    )
assert welcome( ) == (
        f"Available Routes:<br/>"
        f"/api/v1.0/precipitation<br/>"
        f"/api/v1.0/stations"
        f"/api/v1.0/tobs <br>"
        f"/api/v1.0/start_date <br> "
        f"/api/v1.0/end_date <br> "
    )
assert welcome() == (
    "Available Routes:<br/>"
    "/api/v1.0/precipitation<br/>"
    "/api/v1.0/stations"
    "/api/v1.0/tobs <br>"
    "/api/v1.0/start_date <br> "
    "/api/v1.0/end_date <br> "
)
assert welcome() == ("Available Routes:<br/>"
    f"/api/v1.0/precipitation<br/>"
    f"/api/v1.0/stations"
    f"/api/v1.0/tobs <br>"
    f"/api/v1.0/start_date <br> "
    f"/api/v1.0/end_date <br> "
)
assert welcome( ) == (
    f"Available Routes:<br/>"
    f"/api/v1.0/precipitation<br/>"
    f"/api/v1.0/stations"
    f"/api/v1.0/tobs <br>"
    f"/api/v1.0/start_date <br> "
    f"/api/v1.0/end_date <br> "
)
