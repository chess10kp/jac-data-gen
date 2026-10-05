"""Main entry point for myapp."""

import from anthropic_helper { analyze_paper_text }

import from .components.Button { Button }

obj AnalysisResult {
    has summaryQuestion: str;
    has summaryMethod: str;
    has summaryFinding: str;
    has keyVariables: str;
    has nextObjective: str;
    has nextExperiment: str;
    has critique: str;
}

def:pub analyze_paper_ai(paper_text: str) -> AnalysisResult {
    result = analyze_paper_text(paper_text);

    return AnalysisResult(
        summaryQuestion=result["summaryQuestion"],
        summaryMethod=result["summaryMethod"],
        summaryFinding=result["summaryFinding"],
        keyVariables=result["keyVariables"],
        nextObjective=result["nextObjective"],
        nextExperiment=result["nextExperiment"],
        critique=result["critique"]
    );
}

def:pub app() -> any {
    has paperText: str = "";
    has loading: bool = False;
    has errorMsg: str = "";
    has resultsDisplay: str = "none";

    has summaryQuestion: str = "";
    has summaryMethod: str = "";
    has summaryFinding: str = "";
    has keyVariables: str = "";
    has nextObjective: str = "";
    has nextExperiment: str = "";
    has critique: str = "";

    has diffusionExample: str = "This study investigates how water content and temperature influence diffusion behavior in basaltic silicate melts. We performed a series of controlled diffusion couple experiments at three temperatures and measured concentration profiles for major elements after each run. The results show that diffusion rates increase with temperature and that some components display coupled behavior rather than diffusing independently. We also find that small differences in starting composition can strongly affect the apparent transport patterns. These observations suggest that multicomponent interactions must be considered when interpreting melt evolution in natural magmatic systems. As a next step, additional experiments on andesitic compositions could test whether the same diffusion relationships hold across a broader compositional range.";

    has lunarExample: str = "This paper examines whether repeated magma recharge can explain the chemical signatures observed in lunar melt inclusions. Using a numerical model constrained by petrologic observations, we compare scenarios with and without recharge and evaluate their ability to reproduce volatile and major element patterns. The results suggest that recharge can account for several previously puzzling observations without requiring an unusually volatile-rich mantle source. However, the model depends on assumptions about recharge frequency and reservoir mixing efficiency. Future work should combine additional geochemical measurements with experimental constraints to test whether the recharge interpretation is unique.";

    has genericExample: str = "This study investigates whether changing nutrient availability affects microbial growth in a controlled laboratory system. The authors compare growth rates across several treatment groups and measure biomass production after a fixed time interval. The results suggest that the response depends strongly on nutrient concentration and is not fully explained by a simple linear trend. The study proposes that additional experiments should examine whether temperature and pH modify the observed relationship.";

    async def handleAnalyze() {
        cleanText: str = paperText.strip();

        if cleanText == "" {
            errorMsg = "Please paste a paper abstract or excerpt first.";
            resultsDisplay = "none";
            return;
        }

        loading = True;
        errorMsg = "";

        try {
            result = await analyze_paper_ai(cleanText);

            summaryQuestion = result.summaryQuestion;
            summaryMethod = result.summaryMethod;
            summaryFinding = result.summaryFinding;
            keyVariables = result.keyVariables;
            nextObjective = result.nextObjective;
            nextExperiment = result.nextExperiment;
            critique = result.critique;

            resultsDisplay = "grid";
        } except Exception as e {
            errorMsg = f"Analysis failed: {e}";
            resultsDisplay = "none";
        }

        loading = False;
    }

    def clearAll() {
        paperText = "";
        loading = False;
        errorMsg = "";
        resultsDisplay = "none";

        summaryQuestion = "";
        summaryMethod = "";
        summaryFinding = "";
        keyVariables = "";
        nextObjective = "";
        nextExperiment = "";
        critique = "";
    }

    def loadDiffusionExample() {
        paperText = diffusionExample;
        errorMsg = "";
    }

    def loadLunarExample() {
        paperText = lunarExample;
        errorMsg = "";
    }

    def loadGenericExample() {
        paperText = genericExample;
        errorMsg = "";
    }

    return
        <div
            style={{
                padding: "2rem",
                fontFamily: "Arial, sans-serif",
                maxWidth: "980px",
                margin: "0 auto",
                backgroundColor: "#fcfcfc"
            }}
        >
            <h1 style={{marginBottom: "0.5rem"}}>
                Scientific Paper-to-Experiment Copilot
            </h1>
            <p style={{fontSize: "1.05rem", color: "#444"}}>
                Turn a paper abstract into a summary, experiment idea, and reviewer-style critique.
            </p>
            <div
                style={{
                    marginTop: "1rem",
                    display: "flex",
                    gap: "0.75rem",
                    flexWrap: "wrap"
                }}
            >
                <Button
                    label="Load Diffusion Example"
                    onClick={lambda { loadDiffusionExample();}}
                    variant="secondary"
                />
                <Button
                    label="Load Lunar Example"
                    onClick={lambda { loadLunarExample();}}
                    variant="secondary"
                />
                <Button
                    label="Load Generic Example"
                    onClick={lambda { loadGenericExample();}}
                    variant="secondary"
                />
            </div>
            <div style={{marginTop: "1.5rem"}}>
                <textarea
                    value={paperText}
                    onChange={lambda (e: any) { paperText = e.target.value;}}
                    placeholder="Paste paper abstract or excerpt here..."
                    style={{
                        width: "100%",
                        minHeight: "220px",
                        padding: "1rem",
                        fontSize: "1rem",
                        border: "1px solid #ccc",
                        borderRadius: "10px",
                        boxSizing: "border-box",
                        backgroundColor: "white"
                    }}
                />
            </div>
            <div
                style={{
                    marginTop: "1rem",
                    display: "flex",
                    gap: "1rem",
                    flexWrap: "wrap"
                }}
            >
                <Button
                    label={(
                        "Analyzing..." if loading else "Generate Research Insight"
                    )}
                    onClick={lambda { handleAnalyze();}}
                    variant="primary"
                />
                <Button
                    label="Clear"
                    onClick={lambda { clearAll();}}
                    variant="secondary"
                />
            </div>
            <div style={{marginTop: "1rem", color: "#b00020", minHeight: "1.5rem"}}>
                {errorMsg}
            </div>
            <div style={{marginTop: "0.5rem", color: "#555", minHeight: "1.5rem"}}>
                {(loading and "Calling Claude...") or ""}
            </div>
            <div style={{marginTop: "2rem", display: resultsDisplay, gap: "1rem"}}>
                <div
                    style={{
                        border: "1px solid #ddd",
                        borderRadius: "12px",
                        padding: "1.25rem",
                        backgroundColor: "#fafafa"
                    }}
                >
                    <h2>
                        Summary
                    </h2>
                    <p>
                        <b>
                            Question:
                        </b>
                        {summaryQuestion}
                    </p>
                    <p>
                        <b>
                            Method:
                        </b>
                        {summaryMethod}
                    </p>
                    <p>
                        <b>
                            Finding:
                        </b>
                        {summaryFinding}
                    </p>
                </div>
                <div
                    style={{
                        border: "1px solid #ddd",
                        borderRadius: "12px",
                        padding: "1.25rem",
                        backgroundColor: "#fafafa"
                    }}
                >
                    <h2>
                        Key Variables
                    </h2>
                    <p>
                        {keyVariables}
                    </p>
                </div>
                <div
                    style={{
                        border: "1px solid #ddd",
                        borderRadius: "12px",
                        padding: "1.25rem",
                        backgroundColor: "#fafafa"
                    }}
                >
                    <h2>
                        Proposed Next Experiment
                    </h2>
                    <p>
                        <b>
                            Objective:
                        </b>
                        {nextObjective}
                    </p>
                    <p>
                        <b>
                            Experiment:
                        </b>
                        {nextExperiment}
                    </p>
                </div>
                <div
                    style={{
                        border: "1px solid #ddd",
                        borderRadius: "12px",
                        padding: "1.25rem",
                        backgroundColor: "#fafafa"
                    }}
                >
                    <h2>
                        Reviewer Critique
                    </h2>
                    <p>
                        {critique}
                    </p>
                </div>
            </div>
        </div>;
}
