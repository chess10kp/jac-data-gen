"""Takes receptions, yards, and touchdowns; returns PPR fantasy points."""
def rec_pts(rec: int, yds: int, tds: int) -> float {
    yds * 0.1 + rec * 1 + tds * 6
}