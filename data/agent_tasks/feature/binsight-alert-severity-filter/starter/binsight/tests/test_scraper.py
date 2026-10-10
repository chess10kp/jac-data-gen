import unittest

from services import scraper


class ScraperTests(unittest.TestCase):
    def test_menu_item_filter_rejects_navigation_noise(self):
        navigation = [
            "Home",
            "Menus & Locations",
            "Contact Us",
            "Dining Halls",
            "Allergens",
            "Vegan",
            "Clear All",
            "Comments & Suggestions",
            "Student Employment",
            "Today’s Hours",
            "1931 Duffield Street, Ann Arbor, MI, 48109",
        ]
        for phrase in navigation:
            self.assertFalse(
                scraper._is_menu_item(phrase),
                f"{phrase!r} should be rejected as navigation/structural noise",
            )

    def test_footer_start_detection(self):
        footer_lines = [
            "Comments & Suggestions",
            "Contact Us",
            "Today’s Hours",
            "1931 Duffield Street, Ann Arbor, MI, 48109",
        ]
        for line in footer_lines:
            self.assertTrue(
                scraper._is_footer_start(line),
                f"{line!r} should be detected as footer content",
            )
        self.assertFalse(scraper._is_footer_start("Garlicky Mashed Potatoes"))

    def test_menu_item_filter_rejects_nutrition_lines(self):
        nutrition = [
            "389mg",
            "24g",
            "Saturated Fat 13g",
            "Sugars 31g",
            "Dietary Fiber 5g",
            "Cholesterol",
            "% Daily Value*",
            "Serving Size",
            "Nutrient Dense Medium",
            "Carbon Footprint Low",
            "Cookie (35g)",
        ]
        for line in nutrition:
            self.assertFalse(
                scraper._is_menu_item(line),
                f"{line!r} should be rejected as nutrition noise",
            )

    def test_nutrition_line_detection(self):
        nutrition = [
            "389mg",
            "24g",
            "Saturated Fat 13g",
            "Sugars 31g",
            "Dietary Fiber 5g",
            "Total Carbohydrate",
        ]
        for line in nutrition:
            self.assertTrue(
                scraper._is_nutrition_line(line),
                f"{line!r} should be detected as a nutrition line",
            )
        self.assertFalse(scraper._is_nutrition_line("Pepperoni Pizza"))
        self.assertFalse(scraper._is_nutrition_line("Oatmeal"))

    def test_menu_item_filter_accepts_food_names(self):
        foods = [
            "Pepperoni Pizza",
            "Garlicky Mashed Potatoes",
            "Beef and Mushroom Blended Burger",
            "Tofu and Broccoli Stir Fry",
            "Sauteed Green Beans",
            "Oatmeal",
            "Scrambled Tofu w/ Spinach",
        ]
        for food in foods:
            self.assertTrue(
                scraper._is_menu_item(food),
                f"{food!r} should be accepted as a menu item",
            )

    def test_meal_period_headers_detected(self):
        for period in ("Breakfast", "Brunch", "Lunch", "Dinner", "breakfast"):
            self.assertTrue(
                scraper._is_meal_period_header(period),
                f"{period!r} should be detected as a meal period header",
            )

    def test_canonicalize_period_normalizes_case(self):
        self.assertEqual(scraper._canonicalize_period("breakfast"), "Breakfast")
        self.assertEqual(scraper._canonicalize_period("DINNER"), "Dinner")


if __name__ == "__main__":
    unittest.main()
