"""Island ferry reservations: public API.

Sailings have deck lanes (car 1, van 2) and passenger seats (foot passengers
only; people in a vehicle stay in it).
"""

import from bookings { add_sailing, book, cancel, move, manifest, free_space, day_passengers }
