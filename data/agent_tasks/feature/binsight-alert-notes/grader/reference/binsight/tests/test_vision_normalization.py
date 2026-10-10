import unittest

from models.schemas import WasteItem
from services import vision


class VisionNormalizationTests(unittest.TestCase):
    def test_normalized_percentages_sum_to_100_by_weight(self):
        items = [
            WasteItem(
                food="Rice",
                category="grain",
                estimated_weight_oz=2.0,
                estimated_portion_wasted_pct=100.0,
                estimated_cost_usd=0.5,
                avoidable=True,
            ),
            WasteItem(
                food="Broccoli",
                category="vegetable",
                estimated_weight_oz=1.0,
                estimated_portion_wasted_pct=100.0,
                estimated_cost_usd=0.25,
                avoidable=True,
            ),
        ]

        normalized = vision._normalize_item_percentages(items)

        total_pct = round(sum(item.estimated_portion_wasted_pct for item in normalized), 1)
        self.assertEqual(total_pct, 100.0)
        self.assertEqual(normalized[0].estimated_portion_wasted_pct, 66.7)
        self.assertEqual(normalized[1].estimated_portion_wasted_pct, 33.3)


if __name__ == "__main__":
    unittest.main()
