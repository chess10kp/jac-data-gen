"""Jac-powered recommendations entrypoint for BinSight."""

walker :pub GenerateRecommendations {
    has analysis_prompt: str;

    can run with Root entry {
        result = {
            "generated_at": "1970-01-01T00:00:00+00:00",
            "menu_delta": [],
            "insights": [],
            "summary_text": (
                "Jac recommendations stub. Replace this walker body with by llm "
                + "or tool-backed recommendation generation while preserving the "
                + "existing response schema. Prompt length: "
                + str(len(self.analysis_prompt))
            )
        };
        report result;
    }
}
