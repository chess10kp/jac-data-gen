def welcome():
    """List all available api routes."""
    return (
        f"Available Routes:<br/>"
        f"/api/v1.0/precipitation<br/>"
        f"/api/v1.0/stations<br/>"
        f"/api/v1.0/tobs<br/>"
        f"/api/v1.0/start/<start><br/>"
        f"/api/v1.0/start/<start>/end/<end>"
    )

assert welcome() == ("Available Routes:<br/>"
                     "/api/v1.0/precipitation<br/>"
                     "/api/v1.0/stations<br/>"
                     "/api/v1.0/tobs<br/>"
                     "/api/v1.0/start/<start><br/>"
                     "/api/v1.0/start/<start>/end/<end>")
assert welcome() == (
        f"Available Routes:<br/>"
        f"/api/v1.0/precipitation<br/>"
        f"/api/v1.0/stations<br/>"
        f"/api/v1.0/tobs<br/>"
        f"/api/v1.0/start/<start><br/>"
        f"/api/v1.0/start/<start>/end/<end>"
    )
assert welcome() == ("Available Routes:<br/>/api/v1.0/precipitation<br/>/api/v1.0/stations<br/>/api/v1.0/tobs<br/>/api/v1.0/start/<start><br/>/api/v1.0/start/<start>/end/<end>")
assert welcome() == (
    "Available Routes:<br/>"
    "/api/v1.0/precipitation<br/>"
    "/api/v1.0/stations<br/>"
    "/api/v1.0/tobs<br/>"
    "/api/v1.0/start/<start><br/>"
    "/api/v1.0/start/<start>/end/<end>"
)
assert welcome() == "Available Routes:<br/>/api/v1.0/precipitation<br/>/api/v1.0/stations<br/>/api/v1.0/tobs<br/>/api/v1.0/start/<start><br/>/api/v1.0/start/<start>/end/<end>"
assert welcome() == (
    f"Available Routes:<br/>"
    f"/api/v1.0/precipitation<br/>"
    f"/api/v1.0/stations<br/>"
    f"/api/v1.0/tobs<br/>"
    f"/api/v1.0/start/<start><br/>"
    f"/api/v1.0/start/<start>/end/<end>"
)
