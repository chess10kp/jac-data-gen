walker Coordinator {
    can coordinate with Root entry {
        research = root spawn Researcher(topic="AI");
        writer = root spawn Writer(style="technical");
        reviewer = root spawn Reviewer();

        report {
            "research": research.reports,
            "draft": writer.reports,
            "review": reviewer.reports
        };
    }
}
