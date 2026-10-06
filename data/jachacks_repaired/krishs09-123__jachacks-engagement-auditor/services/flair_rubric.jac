glob FLAIR_CATEGORY_VISUAL: str = "Visual Clarity";
glob FLAIR_CATEGORY_TEXTUAL: str = "Textual Clarity";
glob FLAIR_CATEGORY_AESTHETICS: str = "Aesthetics";
glob FLAIR_ALLOWED_CATEGORIES: list[str] = [
    FLAIR_CATEGORY_VISUAL,
    FLAIR_CATEGORY_TEXTUAL,
    FLAIR_CATEGORY_AESTHETICS,
];
glob FLAIR_ALLOWED_PRIORITIES: list[str] = ["Low", "Medium", "High"];
glob FLAIR_ALLOWED_ELEMENTS: list[str] = [
    "Typography",
    "Color",
    "Layout",
    "Buttons",
    "Imagery",
    "Navigation",
];
glob FLAIR_FORBIDDEN_PHRASES: list[str] = [
    "captured page states",
    "grouped evidence",
    "choice density",
    "cognitive cost",
    "signal affordances",
    "visual anchor",
    "reduce nearby secondary competition",
    "extreme brightness",
    "page state",
    "ux heuristic",
    "hick's law",
    "fitts's law",
    "cognitive load theory",
    "neuroscience",
    "behavioral science",
    "according to studies",
    "research shows",
    "best practices suggest",
    "crawler score",
    "clickable element count",
    "screenshot confidence",
    "computer vision metrics",
    "processing fluency",
];
glob FLAIR_VAGUE_PHRASES: list[str] = [
    "improve visual hierarchy",
    "make layout cleaner",
    "enhance readability",
    "use better contrast",
    "optimize the cta",
    "reduce cognitive load",
    "make one visual anchor obvious",
    "use spacing and grouping",
    "improve hierarchy",
    "improve clarity",
    "make it cleaner",
    "polish the design",
    "optimize layout",
    "enhance aesthetics",
];
glob FLAIR_PAGE_OBJECT_TERMS: list[str] = [
    "hero",
    "headline",
    "subheading",
    "cta",
    "button",
    "navigation",
    "nav",
    "pricing",
    "card",
    "footer",
    "image",
    "illustration",
    "screenshot",
    "testimonial",
    "references",
    "reference",
    "form",
    "sidebar",
    "search",
    "menu",
    "cookie banner",
    "popup",
    "modal",
    "feature grid",
    "product section",
    "product visual",
    "download",
    "signup",
    "sign up",
    "login",
    "log in",
    "header",
    "section",
    "first screen",
];
glob FLAIR_GENERIC_TARGETS: list[str] = [
    "layout",
    "page",
    "visual hierarchy",
    "clarity",
    "design",
    "aesthetics",
    "content",
    "section",
    "interface",
    "website",
    "site",
    "user experience",
];
glob FLAIR_TARGET_STOPWORDS: list[str] = [
    "the",
    "a",
    "an",
    "top",
    "main",
    "primary",
    "secondary",
    "visible",
    "specific",
    "page",
    "section",
    "area",
    "part",
    "like",
    "near",
    "above",
    "below",
    "fold",
];
glob FLAIR_REGENERATION_PROMPT: str = "The previous audit was too vague, too narrow, or not evidence-bound enough. Regenerate the audit as a stricter manual UI/UX critique. Audit multiple page sections. Every issue must name a specific target element, location, concrete problem, matching recommendation, and evidence that supports the same exact target. Keep the scoring scale unchanged: Low = -1, Medium = -2, High = -3.";

obj FlairRubricIssue {
    has category: str = "";
    has priority: str = "";
    has element: str = "";
    has target_element: str = "";
    has location: str = "";
    has visible_text: str = "";
    has deduction: int = 0;
    has problem: str = "";
    has recommendation: str = "";
    has screenshot_observation: str = "";
    has crawler_text_observation: str = "";
    has evidence_confidence: str = "Low";
    has valid: bool = False;
    has message: str = "";
}

obj FlairAuditQualityResult {
    has needs_regeneration: bool = False;
    has reasons: list[str] = [];
    has valid_issue_count: int = 0;
    has distinct_target_count: int = 0;
    has distinct_area_count: int = 0;
}

obj FlairScoreResult {
    has visual_clarity: int = 100;
    has textual_clarity: int = 100;
    has aesthetics: int = 100;
    has valid_issue_count: int = 0;
    has rejected_issue_count: int = 0;
    has corrections: list[str] = [];
}

def flair_rubric_prompt() -> str {
    parts: list[str] = [
        "You are Flair, a strict UI/UX audit engine.",
        "You audit websites using: 1. A screenshot from the crawler 2. Text extracted from the crawler 3. Optional URL/title metadata.",
        "Your job is to produce a concise manual-style website audit.",
        "Do not be vague. Do not be polite for its own sake. Do not give generic design advice. Do not mention crawler metrics. Do not mention studies or UX theory. Do not invent issues that are not visible or supported. Do not attach evidence to the wrong issue.",
        "You must identify specific problems across the website.",
        "For a normal full-page audit, return 5 to 9 issues.",
        "Each issue must target a concrete page element, such as hero section, headline, subheadline, CTA button, navigation, image, illustration, product screenshot, feature grid, product card, pricing card, references section, testimonial section, footer, form, popup, or cookie banner.",
        "Each issue must include category, priority, element, targetElement, location, visibleText if relevant, problem, recommendation, and evidence.",
        "Allowed categories: Visual Clarity, Textual Clarity, Aesthetics.",
        "Allowed priorities: Low, Medium, High. Priority deductions: Low = -1, Medium = -2, High = -3.",
        "Allowed element labels: Typography, Color, Layout, Buttons, Imagery, Navigation. Element does not affect score.",
        "The application will calculate final scores. Do not calculate scores yourself unless the app requires model-suggested scores.",
        "Use Visual Clarity when the interface is harder to scan, understand, or use: primary CTA is buried, hero has too many competing messages, navigation is overloaded, layout scatters related information, feature cards are too dense, or important content is visually weak.",
        "Use Textual Clarity when the words, message, claims, or section order are unclear: headline does not explain the product, value proposition is vague, references appear disconnected from the product story, copy gives too much detail too early, CTA text is unclear, or benefits are not prioritized.",
        "Use Aesthetics when the design hurts polish, trust, or brand fit: colors feel jarring, imagery feels abstract or unprofessional, card styles are inconsistent, visuals feel generic, or spacing/styling makes the page feel less credible.",
        "Use High when the issue hurts the main user journey, first impression, comprehension, credibility, or conversion.",
        "Use Medium when the issue causes noticeable friction but does not break the page.",
        "Use Low for localized polish issues.",
        "Before final issues, internally inspect the website section by section: hero, navigation, CTA/buttons, text/copy, layout, imagery, color/aesthetics, and supporting sections.",
        "When present, inspect hero section, main headline, subheadline, primary CTA, secondary CTA, navigation, product explanation, feature grid, cards, imagery or illustrations, pricing section, testimonials, references/proof section, footer, forms, and visible popups/banners/overlays.",
        "Minimum coverage rule: for normal full-page evidence, usually audit at least four distinct targets across hero/message, CTA/buttons, navigation or layout, imagery/color/aesthetic polish, and supporting sections such as features, proof, references, pricing, or footer.",
        "Do not return only one issue unless the screenshot and crawler text are genuinely limited.",
        "Every issue must be tied to one exact target element. Good targetElement values: hero headline, hero CTA button, top navigation, neuron-like hero image, references section, feature card grid, download button, pricing card, footer links. Bad targetElement values: layout, page, visual hierarchy, clarity, design.",
        "Evidence must describe the same target element as the issue. If evidence does not clearly support the issue, set that evidence field to null. Never attach unrelated screenshot evidence to an issue.",
        "The recommendation must directly fix the same target element or section named in the problem. Reject and rewrite any issue where the recommendation does not modify the same target.",
        "Every issue must pass this specificity test: it names a concrete page element, identifies what is wrong with that element, explains why that hurts clarity/conversion/trust/aesthetics, gives a concrete design or content change, and uses evidence that refers to the same element.",
        "Forbidden vague phrases: improve clarity, improve hierarchy, make it cleaner, optimize layout, enhance aesthetics, reduce friction, reduce cognitive load, use better spacing, use better contrast, make the design more polished, visual anchor, choice density, cognitive cost, captured page states, grouped evidence, signal affordances, UX heuristic, studies show, research shows, best practices suggest.",
        "Do not mention crawler internals, clickable element counts, internal scores, page-state metrics, or computer vision metrics in the user-facing audit.",
        "Return strict JSON only. No markdown. No prose outside JSON.",
        "Use this exact JSON shape:",
        "{\"website\":\"string\",\"url\":\"string | null\",\"inferredContext\":{\"websiteType\":\"string\",\"primaryAudience\":\"string\",\"primaryGoal\":\"string\",\"mainUserAction\":\"string\",\"mainValueProposition\":\"string\",\"pageMode\":\"informational | transactional | promotional | functional | navigational | mixed | unknown\"},\"sectionCoverage\":{\"sectionsDetected\":[\"string\"],\"sectionsAudited\":[\"string\"],\"coverageNotes\":\"string\"},\"issues\":[{\"category\":\"Visual Clarity | Textual Clarity | Aesthetics\",\"priority\":\"Low | Medium | High\",\"element\":\"Typography | Color | Layout | Buttons | Imagery | Navigation\",\"targetElement\":\"string\",\"location\":\"string\",\"visibleText\":\"string | null\",\"deduction\":-1,\"problem\":\"string\",\"recommendation\":\"string\",\"evidence\":{\"screenshotObservation\":\"string | null\",\"crawlerTextObservation\":\"string | null\",\"evidenceConfidence\":\"High | Medium | Low\"}}],\"limitations\":[\"string\"]}",
    ];
    return "\n".join(parts);
}

def clamp_flair_score(score: int) -> int {
    if score < 0 {
        return 0;
    }
    if score > 100 {
        return 100;
    }
    return score;
}

def normalize_category(value: str) -> str {
    lowered: str = value.strip().lower();
    if lowered in ["visual clarity", "visual"] {
        return FLAIR_CATEGORY_VISUAL;
    }
    if lowered in ["textual clarity", "textual", "copy"] {
        return FLAIR_CATEGORY_TEXTUAL;
    }
    if lowered in ["aesthetics", "aesthetic", "visual polish"] {
        return FLAIR_CATEGORY_AESTHETICS;
    }
    return "";
}

def normalize_priority(value: str) -> str {
    normalized: str = value.strip().lower();
    if normalized == "low" {
        return "Low";
    }
    if normalized == "medium" {
        return "Medium";
    }
    if normalized == "high" {
        return "High";
    }
    return "";
}

def normalize_element(value: str) -> str {
    normalized: str = value.strip().lower();
    if normalized == "typography" {
        return "Typography";
    }
    if normalized == "color" or normalized == "colour" {
        return "Color";
    }
    if normalized == "layout" {
        return "Layout";
    }
    if normalized == "buttons" or normalized == "button" or normalized == "cta" or normalized == "ctas" {
        return "Buttons";
    }
    if normalized == "imagery" or normalized == "image" or normalized == "images" {
        return "Imagery";
    }
    if normalized == "navigation" or normalized == "nav" {
        return "Navigation";
    }
    return "";
}

def normalize_evidence_confidence(value: str) -> str {
    normalized: str = value.strip().lower();
    if normalized == "high" {
        return "High";
    }
    if normalized == "medium" {
        return "Medium";
    }
    if normalized == "low" {
        return "Low";
    }
    return "Low";
}

def category_to_pillar(category: str) -> str {
    normalized: str = normalize_category(category);
    if normalized == FLAIR_CATEGORY_TEXTUAL {
        return "textual";
    }
    if normalized == FLAIR_CATEGORY_VISUAL {
        return "visual";
    }
    if normalized == FLAIR_CATEGORY_AESTHETICS {
        return "aesthetics";
    }
    return "";
}

def pillar_to_category(pillar: str) -> str {
    lowered: str = pillar.strip().lower();
    if lowered == "textual" {
        return FLAIR_CATEGORY_TEXTUAL;
    }
    if lowered == "visual" {
        return FLAIR_CATEGORY_VISUAL;
    }
    if lowered == "aesthetics" or lowered == "aesthetic" {
        return FLAIR_CATEGORY_AESTHETICS;
    }
    return "";
}

def deduction_for_priority(priority: str) -> int {
    normalized: str = normalize_priority(priority);
    if normalized == "High" {
        return -3;
    }
    if normalized == "Medium" {
        return -2;
    }
    if normalized == "Low" {
        return -1;
    }
    return 0;
}

def contains_phrase(value: str, phrases: list[str]) -> bool {
    lowered: str = value.lower();
    for phrase in phrases {
        if phrase in lowered {
            return True;
        }
    }
    return False;
}

def contains_forbidden_flair_language(value: str) -> bool {
    return contains_phrase(value, FLAIR_FORBIDDEN_PHRASES);
}

def contains_vague_flair_language(value: str) -> bool {
    return contains_phrase(value, FLAIR_VAGUE_PHRASES);
}

def contains_specific_page_object(value: str) -> bool {
    return contains_phrase(value, FLAIR_PAGE_OBJECT_TERMS);
}

def is_generic_target_element(value: str) -> bool {
    lowered: str = value.strip().lower();
    if len(lowered) == 0 {
        return True;
    }
    return lowered in FLAIR_GENERIC_TARGETS;
}

def is_specific_location(value: str) -> bool {
    lowered: str = value.strip().lower();
    if len(lowered) == 0 {
        return False;
    }
    if lowered in ["page", "website", "site", "layout", "design", "unknown", "n/a", "none"] {
        return False;
    }
    return len(lowered) >= 5;
}

def clean_token(value: str) -> str {
    cleaned: str = value.lower();
    for mark in [",", ".", ":", ";", "!", "?", "(", ")", "[", "]", "{", "}", "\"", "'", "`", "-", "_", "/"] {
        cleaned = cleaned.replace(mark, " ");
    }
    return cleaned.strip();
}

def target_terms(target_element: str) -> list[str] {
    terms: list[str] = [];
    cleaned: str = clean_token(target_element);
    for token in cleaned.split() {
        if len(token) > 2 and token not in FLAIR_TARGET_STOPWORDS and token not in terms {
            terms.append(token);
        }
    }
    if "cta" in cleaned and "button" not in terms {
        terms.append("button");
    }
    if "nav" in cleaned and "navigation" not in terms {
        terms.append("navigation");
    }
    return terms;
}

def target_matches_text(target_element: str, value: str) -> bool {
    lowered_target: str = target_element.strip().lower();
    lowered_value: str = value.strip().lower();
    if len(lowered_target) == 0 or len(lowered_value) == 0 {
        return False;
    }
    if lowered_target in lowered_value {
        return True;
    }
    for term in target_terms(target_element) {
        if term in lowered_value {
            return True;
        }
    }
    return False;
}

def issue_area(target_element: str) -> str {
    lowered: str = target_element.lower();
    if "hero" in lowered or "headline" in lowered or "subheadline" in lowered {
        return "hero/message";
    }
    if "cta" in lowered or "button" in lowered or "download" in lowered or "signup" in lowered or "sign up" in lowered {
        return "cta/buttons";
    }
    if "nav" in lowered or "menu" in lowered or "header" in lowered {
        return "navigation";
    }
    if "image" in lowered or "illustration" in lowered or "screenshot" in lowered or "color" in lowered {
        return "imagery/color";
    }
    if "pricing" in lowered or "testimonial" in lowered or "reference" in lowered or "proof" in lowered or "footer" in lowered or "feature" in lowered or "card" in lowered or "form" in lowered {
        return "supporting sections";
    }
    return "other";
}

def validate_rubric_issue(
    category: str,
    priority: str,
    element: str,
    deduction: int,
    problem: str,
    recommendation: str,
    screenshot_observation: str = "",
    crawler_text_observation: str = "",
    target_element: str = "",
    location: str = "",
    visible_text: str = "",
    evidence_confidence: str = "Low",
) -> FlairRubricIssue {
    normalized_category: str = normalize_category(category);
    normalized_priority: str = normalize_priority(priority);
    normalized_element: str = normalize_element(element);
    normalized_confidence: str = normalize_evidence_confidence(evidence_confidence);
    clean_target: str = target_element.strip();
    clean_location: str = location.strip();
    clean_visible_text: str = visible_text.strip();
    clean_problem: str = problem.strip();
    clean_recommendation: str = recommendation.strip();
    clean_screenshot_observation: str = screenshot_observation.strip();
    clean_crawler_text_observation: str = crawler_text_observation.strip();
    visible_combo: str = clean_problem + " " + clean_recommendation;
    all_text: str = visible_combo + " " + clean_screenshot_observation + " " + clean_crawler_text_observation + " " + clean_target + " " + clean_location;
    messages: list[str] = [];

    if len(normalized_category) == 0 {
        messages.append("Unknown category");
    }
    if len(normalized_priority) == 0 {
        messages.append("Unknown priority");
    }
    if len(normalized_element) == 0 {
        messages.append("Unknown element");
    }
    if len(clean_problem) == 0 {
        messages.append("Problem is required");
    }
    if len(clean_recommendation) == 0 {
        messages.append("Recommendation is required");
    }
    if is_generic_target_element(clean_target) {
        messages.append("Specific targetElement is required");
    }
    if not is_specific_location(clean_location) {
        messages.append("Specific location is required");
    }
    if contains_forbidden_flair_language(all_text) {
        messages.append("Forbidden vague or internal language");
    }
    if contains_vague_flair_language(visible_combo) {
        messages.append("Problem or recommendation is too vague");
    }
    if not contains_specific_page_object(visible_combo + " " + clean_target) {
        messages.append("Specific page object is required");
    }
    if len(clean_target) > 0 and not target_matches_text(clean_target, clean_problem) {
        messages.append("Problem must reference targetElement");
    }
    if len(clean_target) > 0 and not target_matches_text(clean_target, clean_recommendation) {
        messages.append("Recommendation must address targetElement");
    }
    if len(clean_screenshot_observation) > 0 and not target_matches_text(clean_target, clean_screenshot_observation) {
        clean_screenshot_observation = "";
        messages.append("Screenshot evidence removed because it did not match targetElement");
    }
    if len(clean_crawler_text_observation) > 0 and not target_matches_text(clean_target, clean_crawler_text_observation) {
        clean_crawler_text_observation = "";
        messages.append("Crawler text evidence removed because it did not match targetElement");
    }

    expected_deduction: int = deduction_for_priority(normalized_priority);
    if len(normalized_priority) > 0 and deduction != expected_deduction {
        messages.append(f"Deduction corrected from {deduction} to {expected_deduction}");
    }

    is_valid: bool = len(normalized_category) > 0 and len(normalized_priority) > 0 and len(normalized_element) > 0 and len(clean_problem) > 0 and len(clean_recommendation) > 0 and not is_generic_target_element(clean_target) and is_specific_location(clean_location) and not contains_forbidden_flair_language(all_text) and not contains_vague_flair_language(visible_combo) and contains_specific_page_object(visible_combo + " " + clean_target) and target_matches_text(clean_target, clean_problem) and target_matches_text(clean_target, clean_recommendation);

    return FlairRubricIssue(
        category=normalized_category,
        priority=normalized_priority,
        element=normalized_element,
        target_element=clean_target,
        location=clean_location,
        visible_text=clean_visible_text,
        deduction=expected_deduction,
        problem=clean_problem,
        recommendation=clean_recommendation,
        screenshot_observation=clean_screenshot_observation,
        crawler_text_observation=clean_crawler_text_observation,
        evidence_confidence=normalized_confidence,
        valid=is_valid,
        message="; ".join(messages),
    );
}

def calculate_flair_scores(issues: list[FlairRubricIssue]) -> FlairScoreResult {
    visual: int = 100;
    textual: int = 100;
    aesthetics: int = 100;
    valid_count: int = 0;
    rejected_count: int = 0;
    corrections: list[str] = [];

    for issue in issues {
        if not issue.valid {
            rejected_count += 1;
            if len(issue.message) > 0 {
                corrections.append(issue.message);
            }
            continue;
        }
        valid_count += 1;
        if len(issue.message) > 0 {
            corrections.append(issue.message);
        }
        if issue.category == FLAIR_CATEGORY_VISUAL {
            visual += issue.deduction;
        } elif issue.category == FLAIR_CATEGORY_TEXTUAL {
            textual += issue.deduction;
        } elif issue.category == FLAIR_CATEGORY_AESTHETICS {
            aesthetics += issue.deduction;
        }
    }

    return FlairScoreResult(
        visual_clarity=clamp_flair_score(visual),
        textual_clarity=clamp_flair_score(textual),
        aesthetics=clamp_flair_score(aesthetics),
        valid_issue_count=valid_count,
        rejected_issue_count=rejected_count,
        corrections=corrections,
    );
}

def distinct_valid_targets(issues: list[FlairRubricIssue]) -> list[str] {
    targets: list[str] = [];
    for issue in issues {
        target: str = issue.target_element.strip().lower();
        if issue.valid and len(target) > 0 and target not in targets {
            targets.append(target);
        }
    }
    return targets;
}

def distinct_valid_areas(issues: list[FlairRubricIssue]) -> list[str] {
    areas: list[str] = [];
    for issue in issues {
        if issue.valid {
            area: str = issue_area(issue.target_element);
            if area not in areas {
                areas.append(area);
            }
        }
    }
    return areas;
}

def validate_flair_audit_quality(issues: list[FlairRubricIssue], normal_full_page: bool) -> FlairAuditQualityResult {
    valid_count: int = 0;
    invalid_count: int = 0;
    reasons: list[str] = [];
    for issue in issues {
        if issue.valid {
            valid_count += 1;
            if "evidence removed" in issue.message.lower() {
                reasons.append("Evidence did not match targetElement");
            }
        } else {
            invalid_count += 1;
            if len(issue.message) > 0 {
                reasons.append(issue.message);
            }
        }
    }
    targets: list[str] = distinct_valid_targets(issues);
    areas: list[str] = distinct_valid_areas(issues);
    if normal_full_page and valid_count < 5 {
        reasons.append("Fewer than 5 valid issues for normal full-page evidence");
    }
    if normal_full_page and len(targets) < 4 {
        reasons.append("Fewer than 4 distinct targetElements audited");
    }
    if normal_full_page and len(areas) < 2 {
        reasons.append("Audit only covers one page area");
    }
    if invalid_count > 0 {
        reasons.append("One or more issues failed validation");
    }
    return FlairAuditQualityResult(
        needs_regeneration=len(reasons) > 0,
        reasons=reasons,
        valid_issue_count=valid_count,
        distinct_target_count=len(targets),
        distinct_area_count=len(areas),
    );
}

def format_flair_user_audit_output(
    website: str,
    url: str,
    issues: list[FlairRubricIssue],
    scores: FlairScoreResult,
) -> str {
    lines: list[str] = [];
    label: str = website if len(website) > 0 else url;
    lines.append(label + ":");
    lines.append("");
    for issue in issues {
        if issue.valid {
            lines.append(issue.category + ", " + issue.priority + ", " + issue.element + ":");
            lines.append("- Target: " + issue.target_element + " - " + issue.location);
            lines.append("- Problem: " + issue.problem);
            lines.append("- Recommendation: " + issue.recommendation);
            lines.append("");
        }
    }
    lines.append("Visual Clarity: " + str(scores.visual_clarity) + "/100");
    lines.append("Textual Clarity: " + str(scores.textual_clarity) + "/100");
    lines.append("Aesthetics: " + str(scores.aesthetics) + "/100");
    return "\n".join(lines);
}
