import unittest
from datetime import datetime, timezone
from unittest.mock import patch

from config import settings
from models.schemas import AnalysisRecord, RecommendationInsight, RecommendationsResult, WasteItem, WasteSummary
from services import recommender


def _sample_record() -> AnalysisRecord:
    return AnalysisRecord(
        id="abc",
        created_at=datetime(2026, 4, 4, tzinfo=timezone.utc),
        image_filename="abc.jpg",
        menu_source="manual",
        menu_url=None,
        menu_items=["Brown Rice", "Broccoli"],
        items=[
            WasteItem(
                food="Brown Rice",
                category="grain",
                estimated_weight_oz=4.0,
                estimated_portion_wasted_pct=50.0,
                estimated_cost_usd=0.75,
                avoidable=True,
            )
        ],
        summary=WasteSummary(
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
        recommendations=None,
        notes="sample",
    )


def _sample_result() -> RecommendationsResult:
    return RecommendationsResult(
        generated_at=datetime(2026, 4, 4, tzinfo=timezone.utc),
        menu_delta=["Brown Rice was wasted more than Broccoli"],
        insights=[
            RecommendationInsight(
                priority="high",
                action="Reduce brown rice portions by 20%",
                rationale="It dominated avoidable waste in the sample scan.",
            )
        ],
        summary_text="Brown rice appears to be overserved.",
    )


class RecommenderServiceTests(unittest.TestCase):
    def setUp(self):
        self._backend = settings.recommendations_backend

    def tearDown(self):
        settings.recommendations_backend = self._backend

    def test_python_backend_skips_jac(self):
        settings.recommendations_backend = "python"
        records = [_sample_record()]

        with patch("services.recommender._generate_with_python_llm", return_value=_sample_result()) as py_mock:
            with patch("services.recommender._generate_with_jac", side_effect=AssertionError("jac should not run")):
                recommender.generate_recommendations(records)

        py_mock.assert_called_once_with(records)

    def test_auto_backend_falls_back_to_jac(self):
        settings.recommendations_backend = "auto"
        records = [_sample_record()]

        with patch("services.recommender._generate_with_python_llm", side_effect=RuntimeError("python unavailable")) as py_mock:
            with patch("services.recommender._generate_with_jac", return_value=_sample_result()) as jac_mock:
                recommender.generate_recommendations(records)

        py_mock.assert_called_once_with(records)
        jac_mock.assert_called_once_with(records)

    def test_jac_backend_surfaces_failure(self):
        settings.recommendations_backend = "jac"
        records = [_sample_record()]

        with patch("services.recommender._generate_with_jac", side_effect=RuntimeError("jac unavailable")):
            with self.assertRaises(RuntimeError) as exc:
                recommender.generate_recommendations(records)

        self.assertIn("jac unavailable", str(exc.exception))

    def test_prompt_contains_menu_and_items(self):
        prompt = recommender.build_recommendation_prompt([_sample_record()])

        self.assertIn("Brown Rice", prompt)
        self.assertIn("Broccoli", prompt)
        self.assertIn("DETECTED WASTE", prompt)


if __name__ == "__main__":
    unittest.main()
