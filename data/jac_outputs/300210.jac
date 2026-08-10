"""return columns based on filters"""
def get_columns(filters: dict[str, object]) -> list[dict[str, str | int]] {
    columns = [
        {
            "fieldname": "item",
            "fieldtype": "Link",
            "label": "Item",
            "options": "Item",
            "width": 250
        },
        {
            "fieldname": "open_qty",
            "fieldtype": "Float",
            "label": "Opening Qty",
            "width": 100
        },
        {"fieldname": "in_qty", "fieldtype": "Float", "label": "In Qty", "width": 100},
        {
            "fieldname": "out_qty",
            "fieldtype": "Float",
            "label": "Out Qty",
            "width": 100
        },
        {
            "fieldname": "balance_qty",
            "fieldtype": "Float",
            "label": "Balance Qty",
            "width": 100
        },
        {
            "fieldname": "unconfirmed_qty",
            "fieldtype": "Float",
            "label": "Unconfirmed Qty",
            "width": 100
        },
        {
            "fieldname": "undelivered_qty",
            "fieldtype": "Float",
            "label": "Undelivered Qty",
            "width": 100
        },
        {
            "fieldname": "defective_qty",
            "fieldtype": "Float",
            "label": "Defective Qty",
            "width": 100
        }
    ];
    columns
}