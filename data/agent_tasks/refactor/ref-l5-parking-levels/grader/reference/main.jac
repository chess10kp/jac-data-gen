"""Multi-level parking garage with standard and EV charging spots: public API.

Times are minutes since opening. Fees are in cents.
"""

import from garage { add_spot, park, where, leave, level_free, takings }
