import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from config import settings
from models.schemas import WasteItem, WasteSummary
from services import vision


def _sample_result():
    return (
        [
            WasteItem(
                food="Brown Rice",
                category="grain",
                estimated_weight_oz=4.0,
                estimated_portion_wasted_pct=50.0,
                estimated_cost_usd=0.75,
                avoidable=True,
            )
        ],
        WasteSummary(
            total_items=1,
            total_estimated_weight_oz=4.0,
            total_estimated_cost_usd=0.75,
            most_wasted_category="grain",
            waste_severity="medium",
            avoidable_weight_oz=4.0,
            unavoidable_weight_oz=0.0,
            avoidable_cost_usd=0.75,
            unavoidable_cost_usd=0.0,
        ),
        "sample",
    )


class VisionServiceTests(unittest.TestCase):
    def setUp(self):
        self._backend = settings.analysis_backend
        self._constants_file = settings.constant_items_file
        self._default_constants = list(settings.default_constant_items)

    def tearDown(self):
        settings.analysis_backend = self._backend
        settings.constant_items_file = self._constants_file
        settings.default_constant_items = self._default_constants

    def test_python_backend_skips_jac(self):
        settings.analysis_backend = "python"
        image_path = Path("fake.jpg")

        with patch("services.vision._analyze_with_python_llm", return_value=_sample_result()) as py_mock:
            with patch("services.vision._analyze_with_jac", side_effect=AssertionError("jac should not run")):
                vision.analyze_waste(image_path, ["Rice"], ["Salad"])

        py_mock.assert_called_once_with(image_path, ["Rice"], ["Salad"])

    def test_auto_backend_falls_back_to_python(self):
        settings.analysis_backend = "auto"
        image_path = Path("fake.jpg")

        with patch("services.vision._analyze_with_jac", side_effect=RuntimeError("jac unavailable")) as jac_mock:
            with patch("services.vision._analyze_with_python_llm", return_value=_sample_result()) as py_mock:
                vision.analyze_waste(image_path, ["Rice"], ["Salad"])

        jac_mock.assert_called_once_with(image_path, ["Rice"], ["Salad"])
        py_mock.assert_called_once_with(image_path, ["Rice"], ["Salad"])

    def test_jac_backend_surfaces_failure(self):
        settings.analysis_backend = "jac"
        image_path = Path("fake.jpg")

        with patch("services.vision._analyze_with_jac", side_effect=RuntimeError("jac unavailable")):
            with self.assertRaises(RuntimeError) as exc:
                vision.analyze_waste(image_path, ["Rice"], ["Salad"])

        self.assertIn("jac unavailable", str(exc.exception))

    def test_load_constant_items_prefers_file(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            constants_file = Path(tmpdir) / "constant_items.txt"
            constants_file.write_text("pizza\nsalad bar\npizza\n")
            settings.constant_items_file = constants_file
            settings.default_constant_items = ["fallback"]

            items = vision.load_constant_items()

        self.assertEqual(items, ["pizza", "salad bar"])


if __name__ == "__main__":
    unittest.main()
