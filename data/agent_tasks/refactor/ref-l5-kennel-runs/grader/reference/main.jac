"""Boarding kennel desk: public API.

Runs of a given size, dog stays booked into runs, billing. A dog fits any run
of its size or larger; the nightly price is fixed at booking time.
"""

import from desk { add_run, reprice, book, check_out, occupancy, free_runs, bill }
