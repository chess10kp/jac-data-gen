walker Researcher {
    has topic: str;
    can go with `root entry { report f"research on {self.topic}"; }
}

walker Writer {
    has style: str;
    can go with `root entry { report f"draft in {self.style} style"; }
}

walker Reviewer {
    can go with `root entry { report "looks good"; }
}

walker Summarizer {
    can go with `root entry { report "one-paragraph summary"; }
}

walker Coordinator {
    can coordinate with `root entry {
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
