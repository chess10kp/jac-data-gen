walker Coordinator {
    can coordinate with Root entry {
        research = root spawn Researcher(topic="AI");
        writer = root spawn Writer(style="technical");
        reviewer = root spawn Reviewer();
        summarizer = root spawn Summarizer();

        report {
            "research": research.reports,
            "draft": writer.reports,
            "review": reviewer.reports,
            "summary": summarizer.reports
        };
    }
}
