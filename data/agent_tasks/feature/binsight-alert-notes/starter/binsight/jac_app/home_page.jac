"""Jac-powered home page content for BinSight."""

walker :pub GetHomePageContent {
    can run with Root entry {
        report {
            "hero_kicker": "JACHACKS DEMO",
            "hero_title": "From dining hall waste to operational evidence in one scan.",
            "hero_body": (
                "BinSight turns dining hall food waste into something managers can actually act on: "
                + "one overhead photo, one structured waste report, and one concrete recommendation "
                + "for what to order differently next week."
            ),
            "start_label": "Start",
            "jac_label": "Why Jac",
            "impacts": [
                {
                    "label": "Waste",
                    "value": "$1.8B",
                    "meta": "estimated annual U.S. dining-hall food waste"
                },
                {
                    "label": "Workflow",
                    "value": "photo, not paperwork",
                    "meta": "staff capture the bin instead of running manual audits"
                },
                {
                    "label": "Decision",
                    "value": "change next week's order",
                    "meta": "surface recurring waste before the next menu cycle"
                }
            ],
            "pitch_title": "Campus food waste is measurable, expensive, and fixable.",
            "pitch_body": [
                "BinSight gives managers proof instead of anecdotes: what was wasted, how much it weighed, how much it cost, and whether the waste was avoidable or unavoidable.",
                "If the waste clearly matches the menu, we keep that context. If it does not, the model is allowed to name what it actually sees. That matters in real bins, where scraps, peels, napkins, and leftovers rarely arrive as clean menu labels."
            ],
            "workflow_steps": [
                {
                    "index": "01",
                    "title": "Scrape the hall menu",
                    "description": "Pull the current dining hall page and filter out navigation noise before it becomes context."
                },
                {
                    "index": "02",
                    "title": "Analyze the overhead bin image",
                    "description": "Break the visible waste into items, weights, composition percentages, cost, and avoidability."
                },
                {
                    "index": "03",
                    "title": "Recommend the next action",
                    "description": "Turn repeated waste patterns into smaller portions, different prep, or better ordering decisions."
                }
            ],
            "jac_title": "We used Jac where the product benefits from explicit agents and structured contracts.",
            "jac_body": (
                "The web app stays stable, while Jac-style walkers make the intelligence layer legible: "
                + "one walker for waste analysis, one for recommendations, both returning strict structured "
                + "outputs the dashboard can trust."
            ),
            "jac_snippet": (
                "walker :pub AnalyzeWaste {\\n"
                + "    has image_path: str;\\n"
                + "    has current_menu: list[str] = [];\\n"
                + "    has constant_items: list[str] = [];\\n\\n"
                + "    can run with Root entry {\\n"
                + "        report { \\\"items\\\": [...], \\\"summary\\\": {...} };\\n"
                + "    }\\n"
                + "}"
            ),
            "jac_chips": ["walker endpoints", "structured reports", "hybrid fallback"],
            "media_cards": [
                {
                    "image_url": "/static/landing/service-line.jpg",
                    "alt": "Dining hall service line ingredients",
                    "label": "what was served"
                },
                {
                    "image_url": "/static/landing/bin-waste-b.jpg",
                    "alt": "Overhead bin image showing dining hall food waste",
                    "label": "what actually got tossed"
                }
            ]
        };
    }
}
