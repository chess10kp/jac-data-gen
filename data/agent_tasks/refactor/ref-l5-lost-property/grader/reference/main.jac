"""Lost-property office for a tram network: public API.

Stations number their own finds (<station>-1, <station>-2, ...). Items can be
claimed, moved to another station, or disposed of when held too long.
"""

import from office { log_item, search, claim, claims_of, transfer, held_at, expire }
