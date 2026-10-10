import unittest
from unittest.mock import patch

from config import settings
from services import home_content


class HomeContentTests(unittest.TestCase):
    def setUp(self):
        self._backend = settings.home_backend

    def tearDown(self):
        settings.home_backend = self._backend

    def test_python_backend_returns_content(self):
        settings.home_backend = "python"

        content = home_content.get_home_content()

        self.assertTrue(content.hero_title)
        self.assertEqual(len(content.workflow_steps), 3)
        self.assertEqual(len(content.media_cards), 2)

    def test_auto_backend_falls_back_to_python(self):
        settings.home_backend = "auto"

        with patch("services.home_content._get_with_jac", side_effect=RuntimeError("jac unavailable")):
            content = home_content.get_home_content()

        self.assertIn("structured contracts", content.jac_title.lower())


if __name__ == "__main__":
    unittest.main()
