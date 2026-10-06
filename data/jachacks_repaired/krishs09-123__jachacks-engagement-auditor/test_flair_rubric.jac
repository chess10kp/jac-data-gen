import from services.flair_rubric {
    FlairRubricIssue,
    FlairScoreResult,
    FlairAuditQualityResult,
    validate_rubric_issue,
    calculate_flair_scores,
    validate_flair_audit_quality,
    deduction_for_priority,
}
import from services.flair { FlairIssue, is_jaseci_manual_audit_url, manual_rubric_issue_from_flair_issue }

def make_issue(category: str, priority: str, element: str, deduction: int = 0) -> FlairRubricIssue {
    return validate_rubric_issue(
        category,
        priority,
        element,
        deduction,
        "The hero section makes the primary CTA button hard to identify.",
        "Move the primary CTA button next to the hero headline and make nearby secondary links quieter.",
        "The screenshot shows the CTA button competing with nearby links.",
        "The crawler text includes the hero headline and CTA label.",
        "hero CTA button",
        "hero section above the fold",
        "Get started",
        "High",
    );
}

def expect_int(label: str, actual: int, expected_value: int) {
    if actual != expected_value {
        raise Exception(label + " expected " + str(expected_value) + " but got " + str(actual));
    }
}

def expect_bool(label: str, actual: bool, expected_value: bool) {
    if actual != expected_value {
        raise Exception(label + " expected " + str(expected_value) + " but got " + str(actual));
    }
}

def make_manual_issue(category: str, priority: str, element: str, problem: str, recommendation: str) -> FlairRubricIssue {
    issue: FlairIssue = FlairIssue(
        audit_id="manual",
        pillar="visual",
        title=problem,
        evidence="",
        priority=priority,
        element=element,
        category=category,
        problem=problem,
        recommendation=recommendation,
        target_element="hero typography",
        location="hero section above the fold",
        deduction=0,
    );
    return manual_rubric_issue_from_flair_issue(issue);
}

with entry {
    expect_bool("Jaseci manual URL with slash", is_jaseci_manual_audit_url("https://www.jaseci.org/"), True);
    expect_bool("Jaseci manual URL without slash", is_jaseci_manual_audit_url("https://www.jaseci.org"), True);
    expect_bool("Non-Jaseci URL does not use manual audit", is_jaseci_manual_audit_url("https://example.com"), False);

    manual_jaseci_scores: FlairScoreResult = calculate_flair_scores([
        make_manual_issue("Visual Clarity", "High", "Typography", "Confusing to users", "Remove"),
        make_manual_issue("Aesthetics", "High", "Color", "Jarring colors kill user experience", "Change to milder colors"),
        make_manual_issue("Visual Clarity", "High", "Layout", "Many promises of Jac products all posed as main points", "Consolidate all into a \"why Jac\" section"),
        make_manual_issue("Textual Clarity", "Medium", "Typography", "References page is unaligned with value proposition of Jac and seems unrelated", "Consolidate into an optional references drop down at the end"),
        make_manual_issue("Aesthetics", "Low", "Imagery", "The neuron-like image in the front is unclear and seems unprofessional", "Replace with an intro video on Jac or a quick value proposition"),
    ]);
    expect_int("Manual Jaseci Visual Clarity", manual_jaseci_scores.visual_clarity, 94);
    expect_int("Manual Jaseci Textual Clarity", manual_jaseci_scores.textual_clarity, 98);
    expect_int("Manual Jaseci Aesthetics", manual_jaseci_scores.aesthetics, 96);

    jaseci_issues: list[FlairRubricIssue] = [
        make_issue("Visual Clarity", "High", "Typography"),
        make_issue("Aesthetics", "High", "Color"),
        make_issue("Visual Clarity", "High", "Layout"),
        make_issue("Textual Clarity", "Medium", "Typography"),
        make_issue("Aesthetics", "Low", "Imagery"),
    ];
    jaseci_scores: FlairScoreResult = calculate_flair_scores(jaseci_issues);
    expect_int("Jaseci Visual Clarity", jaseci_scores.visual_clarity, 94);
    expect_int("Jaseci Textual Clarity", jaseci_scores.textual_clarity, 98);
    expect_int("Jaseci Aesthetics", jaseci_scores.aesthetics, 96);

    blender_issues: list[FlairRubricIssue] = [
        make_issue("Visual Clarity", "Low", "Imagery"),
        make_issue("Textual Clarity", "Low", "Typography"),
        make_issue("Aesthetics", "Low", "Color"),
        make_issue("Visual Clarity", "High", "Layout"),
    ];
    blender_scores: FlairScoreResult = calculate_flair_scores(blender_issues);
    expect_int("Blender Visual Clarity", blender_scores.visual_clarity, 96);
    expect_int("Blender Textual Clarity", blender_scores.textual_clarity, 99);
    expect_int("Blender Aesthetics", blender_scores.aesthetics, 99);

    empty_scores: FlairScoreResult = calculate_flair_scores([]);
    expect_int("Empty Visual Clarity", empty_scores.visual_clarity, 100);
    expect_int("Empty Textual Clarity", empty_scores.textual_clarity, 100);
    expect_int("Empty Aesthetics", empty_scores.aesthetics, 100);

    many_issues: list[FlairRubricIssue] = [];
    for i in range(40) {
        many_issues.append(make_issue("Visual Clarity", "High", "Layout"));
    }
    clamped_scores: FlairScoreResult = calculate_flair_scores(many_issues);
    expect_int("Many issues clamp Visual Clarity", clamped_scores.visual_clarity, 0);
    expect_int("Many issues keep Textual Clarity", clamped_scores.textual_clarity, 100);
    expect_int("Many issues keep Aesthetics", clamped_scores.aesthetics, 100);

    corrected: FlairRubricIssue = make_issue("Aesthetics", "High", "Color", -1);
    expect_int("Invalid deduction corrected from priority", corrected.deduction, -3);
    expect_int("Low priority remains -1", deduction_for_priority("Low"), -1);
    expect_int("Medium priority remains -2", deduction_for_priority("Medium"), -2);
    expect_int("High priority remains -3", deduction_for_priority("High"), -3);

    unknown: FlairRubricIssue = make_issue("Conversion", "Urgent", "Animation");
    unknown_scores: FlairScoreResult = calculate_flair_scores([unknown]);
    expect_int("Unknown fields rejected", unknown_scores.rejected_issue_count, 1);
    expect_int("Unknown fields do not affect Visual Clarity", unknown_scores.visual_clarity, 100);

    forbidden: FlairRubricIssue = validate_rubric_issue(
        "Visual Clarity",
        "High",
        "Layout",
        -3,
        "Visual hierarchy loses clarity across captured page states.",
        "Make one visual anchor obvious in the hero section.",
        "Grouped evidence from the screenshot.",
        "",
        "hero section",
        "above the fold",
        "",
        "High",
    );
    expect_bool("Forbidden vague phrases rejected", forbidden.valid, False);

    generic: FlairRubricIssue = validate_rubric_issue(
        "Aesthetics",
        "Medium",
        "Color",
        -2,
        "Confusing to users.",
        "Make it cleaner.",
        "",
        "",
        "hero section",
        "above the fold",
        "",
        "Low",
    );
    expect_bool("Generic issue without page object rejected", generic.valid, False);

    generic_target: FlairRubricIssue = validate_rubric_issue(
        "Visual Clarity",
        "Medium",
        "Layout",
        -2,
        "The layout makes the hero CTA button hard to identify.",
        "Move the hero CTA button closer to the headline.",
        "",
        "",
        "layout",
        "page",
        "",
        "Low",
    );
    expect_bool("Generic targetElement rejected", generic_target.valid, False);

    specific: FlairRubricIssue = validate_rubric_issue(
        "Textual Clarity",
        "Medium",
        "Typography",
        -2,
        "The references section appears before the product value is fully explained.",
        "Move the references section into an optional dropdown near the footer.",
        "",
        "The crawler text shows references before the main product explanation.",
        "references section",
        "middle of page before the product explanation",
        "References",
        "Medium",
    );
    expect_bool("Specific page-object issue accepted", specific.valid, True);

    mismatched_evidence: FlairRubricIssue = validate_rubric_issue(
        "Visual Clarity",
        "High",
        "Buttons",
        -3,
        "The hero CTA button is visually weaker than nearby secondary text.",
        "Make the hero CTA button larger and place it directly under the headline.",
        "The footer contains many legal links.",
        "",
        "hero CTA button",
        "hero section above the fold",
        "Start now",
        "High",
    );
    expect_bool("Mismatched evidence issue remains valid", mismatched_evidence.valid, True);
    if len(mismatched_evidence.screenshot_observation) != 0 {
        raise Exception("Mismatched screenshot evidence should be nulled out.");
    }
    evidence_quality: FlairAuditQualityResult = validate_flair_audit_quality([
        mismatched_evidence,
        make_issue("Visual Clarity", "High", "Layout"),
        make_issue("Textual Clarity", "Medium", "Typography"),
        make_issue("Aesthetics", "Low", "Imagery"),
        make_issue("Visual Clarity", "Low", "Buttons"),
        make_issue("Aesthetics", "Medium", "Color"),
    ], True);
    expect_bool("Mismatched evidence triggers regeneration", evidence_quality.needs_regeneration, True);

    mismatch_recommendation: FlairRubricIssue = validate_rubric_issue(
        "Aesthetics",
        "Medium",
        "Imagery",
        -2,
        "The hero image is abstract and does not explain the product.",
        "Rewrite the navigation labels so the product path is clearer.",
        "The screenshot shows the hero image beside the headline.",
        "",
        "hero image",
        "hero section above the fold",
        "",
        "High",
    );
    expect_bool("Recommendation must address targetElement", mismatch_recommendation.valid, False);

    narrow_quality: FlairAuditQualityResult = validate_flair_audit_quality([
        make_issue("Visual Clarity", "High", "Layout"),
        make_issue("Textual Clarity", "Medium", "Typography"),
        make_issue("Aesthetics", "Low", "Imagery"),
    ], True);
    expect_bool("Fewer than 5 issues triggers regeneration", narrow_quality.needs_regeneration, True);

    same_target_quality: FlairAuditQualityResult = validate_flair_audit_quality([
        make_issue("Visual Clarity", "High", "Layout"),
        make_issue("Textual Clarity", "Medium", "Typography"),
        make_issue("Aesthetics", "Low", "Imagery"),
        make_issue("Visual Clarity", "Low", "Buttons"),
        make_issue("Aesthetics", "Medium", "Color"),
    ], True);
    expect_bool("Fewer than 4 targets triggers regeneration", same_target_quality.needs_regeneration, True);

    mismatch_quality: FlairAuditQualityResult = validate_flair_audit_quality([
        mismatch_recommendation,
        make_issue("Visual Clarity", "High", "Layout"),
        make_issue("Textual Clarity", "Medium", "Typography"),
        make_issue("Aesthetics", "Low", "Imagery"),
        make_issue("Visual Clarity", "Low", "Buttons"),
        make_issue("Aesthetics", "Medium", "Color"),
    ], True);
    expect_bool("Recommendation mismatch triggers regeneration", mismatch_quality.needs_regeneration, True);

    duplicate_scores: FlairScoreResult = calculate_flair_scores([
        make_issue("Visual Clarity", "High", "Layout"),
        make_issue("Visual Clarity", "High", "Layout"),
    ]);
    expect_int("Duplicate valid issues are still scored", duplicate_scores.visual_clarity, 94);

    print("Flair rubric scoring tests passed.");
}
