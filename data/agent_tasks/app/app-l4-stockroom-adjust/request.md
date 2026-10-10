Small stockroom API for a bike repair shop. This is a `jac create --kind service` project; please replace the sample code.

One public walker endpoint, `adjust_stock` (`POST /walker/adjust_stock`):
- fields: `sku: str`, `delta: int` (positive = received, negative = used in a repair), optional `reason: str` (default `""`)
- SKU codes are case-insensitive; store them upper-case
- an unknown SKU with a positive delta creates it; an unknown SKU with a negative or zero delta is an error
- quantity can never go below zero — if the adjustment would do that, report `{"error": "insufficient stock", "quantity": <current qty>}` and don't change anything
- success reports `{"sku": "<SKU>", "quantity": <new qty>, "movements": <number of successful adjustments ever applied to this sku>}`

Keep each successful adjustment as its own node linked to the item (delta + reason), and keep everything under root. Add tests.
