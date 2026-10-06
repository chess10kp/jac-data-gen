import from "@jac/runtime" {
    Link as RuntimeLink,
    jacIsLoggedIn as runtimeIsLoggedIn,
}
import from ..services.flair { FlairAudit, list_flair_audits }
import from ..components.AppShell { AppShell }
import from ..components.FlairIcons { ArrowUpRightIcon, SearchIcon }
import from ..components.FlairShared { PageHeader, Tag }

def pad2(value: int) -> str {
    if value < 10 {
        return "0" + str(value);
    }
    return str(value);
}

def matchesAudit(audit: FlairAudit, query: str) -> bool {
    query_clean: str = query.strip().lower();
    if len(query_clean) > 0 and query_clean not in audit.name.lower() and query_clean not in audit.target_url.lower() {
        return False;
    }
    return True;
}

def categoryFromAudit(audit: FlairAudit) -> str {
    if audit.textual_score <= audit.aesthetics_score and audit.textual_score <= audit.visual_score {
        return "Textual Clarity";
    }
    if audit.visual_score <= audit.aesthetics_score and audit.visual_score <= audit.textual_score {
        return "Visual Clarity";
    }
    return "Aesthetics";
}

def activeCategoryFor(audit: FlairAudit, selected_category: str) -> str {
    if selected_category != "All" {
        return selected_category;
    }
    return categoryFromAudit(audit);
}

def elementForCategory(category_name: str) -> str {
    if category_name == "Textual Clarity" {
        return "Typography";
    }
    if category_name == "Visual Clarity" {
        return "Color";
    }
    return "Layout";
}

def matchesAuditFilters(
    audit: FlairAudit,
    query: str,
    selected_category: str,
    selected_priority: str,
    selected_element: str,
) -> bool {
    if not matchesAudit(audit, query) {
        return False;
    }
    active_category: str = activeCategoryFor(audit, selected_category);
    active_priority: str = priorityFromScore(scoreForCategory(audit, active_category));
    active_element: str = elementForCategory(active_category);
    if selected_priority != "All" and selected_priority != active_priority {
        return False;
    }
    if selected_element != "All" and selected_element != active_element {
        return False;
    }
    return True;
}

def filteredAudits(
    audits: list[FlairAudit],
    query: str,
    selected_category: str,
    selected_priority: str,
    selected_element: str,
) -> list[FlairAudit] {
    rows: list[FlairAudit] = [];
    for audit in audits {
        if matchesAuditFilters(audit, query, selected_category, selected_priority, selected_element) {
            rows.append(audit);
        }
    }
    return rows;
}

def scoreForCategory(audit: FlairAudit, category: str) -> int {
    if category == "Textual Clarity" {
        return audit.textual_score;
    }
    if category == "Visual Clarity" {
        return audit.visual_score;
    }
    return audit.aesthetics_score;
}

def priorityFromScore(score: int) -> str {
    if score < 72 {
        return "High";
    }
    if score < 86 {
        return "Medium";
    }
    return "Low";
}

def:pub FilterButton(option: str, value: str, onSelect: any) -> JsxElement {
    active: bool = option == value;

    def choose(e: MouseEvent) -> None {
        onSelect(option);
    }

    return <button
        onClick={choose}
        className={"relative px-4 py-1.5 rounded-full text-xs font-medium transition-all duration-300 " + ("bg-foreground text-background shadow-sm scale-[1.02]" if active else "text-muted-foreground hover:text-foreground")}
    >
        {option}
    </button>;
}

def:pub FilterRow(label: str, options: list[str], value: str, onSelect: any) -> JsxElement {
    return <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
        <span className="text-[10px] font-mono uppercase tracking-[0.3em] text-muted-foreground sm:w-44 sm:text-right">
            {label}
        </span>
        <div className="inline-flex flex-wrap justify-center gap-1.5 bg-surface/70 border border-border rounded-full p-1 backdrop-blur">
            {[<FilterButton key={option} option={option} value={value} onSelect={onSelect} /> for option in options]}
        </div>
    </div>;
}

def:pub AuditListPage() -> JsxElement {
    has audits: list[FlairAudit] = [];
    has query: str = "";
    has selected_category: str = "All";
    has selected_priority: str = "All";
    has selected_element: str = "All";
    has loading: bool = True;
    has error: str = "";
    filtered: list[FlairAudit] = filteredAudits(audits, query, selected_category, selected_priority, selected_element);
    category_options: list[str] = ["All", "Aesthetics", "Visual Clarity", "Textual Clarity"];
    priority_options: list[str] = ["All", "Low", "Medium", "High"];
    element_options: list[str] = ["All", "Typography", "Color", "Layout", "Buttons", "Imagery", "Navigation"];

    async def loadAudits() -> None {
        if not runtimeIsLoggedIn() {
            return;
        }
        try {
            loaded_audits: list[FlairAudit] = [];
            loaded_audits = await list_flair_audits();
            audits = loaded_audits;
        } except Exception as e {
            error = "Could not load audits: " + str(e);
        }
        loading = False;
    }

    async can with entry {
        await loadAudits();
    }

    def handleQuery(e: ChangeEvent) -> None {
        query = e.target.value;
    }

    def selectCategory(value: str) -> None {
        selected_category = value;
    }

    def selectPriority(value: str) -> None {
        selected_priority = value;
    }

    def selectElement(value: str) -> None {
        selected_element = value;
    }

    return <AppShell>
        <div className="min-h-screen flex flex-col">
            <PageHeader crumb="Audits" />

            <div className="px-6 py-14 max-w-5xl mx-auto w-full text-center">
                <div className="animate-fade-up">
                    <h1 className="font-display text-[clamp(3.5rem,9vw,7rem)] leading-[0.9] tracking-tight">
                        List of <em className="italic text-shimmer">audits</em>
                    </h1>
                    <p className="mt-4 max-w-md mx-auto text-sm text-muted-foreground">
                        A living archive of every site you've audited
                    </p>
                </div>

                <div className="mt-10 max-w-md mx-auto animate-fade-up [animation-delay:120ms]">
                    <label className="relative block">
                        <SearchIcon className="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 text-muted-foreground" />
                        <input
                            value={query}
                            onChange={handleQuery}
                            placeholder="Search audits..."
                            className="w-full bg-card border border-border rounded-full pl-11 pr-5 py-3 text-sm outline-none focus:border-primary transition shadow-sm"
                        />
                    </label>
                </div>

                <div className="mt-12 space-y-5 animate-fade-up [animation-delay:200ms]">
                    <FilterRow label="Sort by category" options={category_options} value={selected_category} onSelect={selectCategory} />
                    <FilterRow label="Sort by priority" options={priority_options} value={selected_priority} onSelect={selectPriority} />
                    <FilterRow label="Sort by element" options={element_options} value={selected_element} onSelect={selectElement} />
                </div>

                {error != "" and <div className="mt-8 paper-card p-5 text-sm text-muted-foreground">{error}</div>}
                {loading and <div className="mt-8 text-sm text-muted-foreground">Loading audits...</div>}

                <div className="mt-12 text-[10px] font-mono uppercase tracking-[0.3em] text-muted-foreground">
                    {"Showing " + str(len(filtered)) + " of " + str(len(audits))}
                </div>

                <div className="mt-6 grid gap-4">
                    {[<RuntimeLink
                        key={filtered[i].uid}
                        to={"/report?audit=" + filtered[i].uid}
                        style={{"animationDelay": str(260 + i * 70) + "ms"}}
                        className="group paper-card hover-lift animate-fade-up text-left px-7 py-6 grid grid-cols-[auto_1fr_auto] items-center gap-6 hover:border-primary"
                    >
                        <span className="font-mono text-[10px] tracking-[0.25em] text-muted-foreground">
                            {"AUDIT " + pad2(i + 1)}
                        </span>

                        <div className="min-w-0">
                            <div className="font-display text-3xl leading-none truncate">
                                {filtered[i].name}
                            </div>
                            <div className="mt-2 flex items-center gap-2 text-[10px] font-mono uppercase tracking-widest text-muted-foreground">
                                <span>{filtered[i].completed_at if filtered[i].completed_at != "" else filtered[i].created_at}</span>
                                <span aria-hidden={True}>.</span>
                                <span className="truncate">{filtered[i].target_url}</span>
                            </div>
                            <div className="mt-3 flex flex-wrap gap-1.5">
                                <Tag>{activeCategoryFor(filtered[i], selected_category)}</Tag>
                                <Tag tone={"primary" if priorityFromScore(scoreForCategory(filtered[i], activeCategoryFor(filtered[i], selected_category))) == "High" else "default"}>
                                    {priorityFromScore(scoreForCategory(filtered[i], activeCategoryFor(filtered[i], selected_category))) + " priority"}
                                </Tag>
                                <Tag>{elementForCategory(activeCategoryFor(filtered[i], selected_category))}</Tag>
                            </div>
                        </div>

                        <div className="flex items-center gap-4">
                            <div className="text-right">
                                <div className="font-display text-4xl leading-none">{scoreForCategory(filtered[i], activeCategoryFor(filtered[i], selected_category))}</div>
                                <div className="text-[10px] font-mono uppercase tracking-widest text-muted-foreground mt-1">
                                    / 100
                                </div>
                            </div>
                            <span className="w-10 h-10 rounded-full grid place-items-center bg-surface group-hover:bg-primary group-hover:text-primary-foreground transition-all duration-300 group-hover:rotate-12">
                                <ArrowUpRightIcon className="w-4 h-4" />
                            </span>
                        </div>
                    </RuntimeLink> for i in range(len(filtered))]}

                    {len(filtered) == 0 and not loading and <div className="paper-card py-16 text-center text-muted-foreground animate-fade-up">
                        <div className="font-display text-2xl italic">Nothing matches.</div>
                        <div className="text-xs mt-2">Try starting a new audit.</div>
                    </div>}
                </div>
            </div>
        </div>
    </AppShell>;
}
