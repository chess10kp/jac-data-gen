
# ── Client Component ──────────────────────────────────────────────────────────
# Depends on: api.jac (save_and_search)

    def:pub app() -> JsxElement {
        # View state
        has view: str = "form";
        has active_tab: str = "stores";
        has error: str = "";

        # Form — location
        has location: str = "";
        has radius: str = "5";

        # Form — hard constraints (tag lists)
        has allergy_input: str = "";
        has allergies: list = [];
        has condition_input: str = "";
        has conditions: list = [];
        has restriction_input: str = "";
        has restrictions: list = [];

        # Form — soft constraints
        has budget: str = "15";
        has calories: str = "2000";
        has protein: str = "150";
        has carbs: str = "200";
        has fat: str = "65";
        has macro_flex: str = "20";

        # Results
        has stores: list = [];
        has recipes: list = [];
        has summary: str = "";
        has expanded_recipe: str = "";

        # ── Shared styles ─────────────────────────────────────────────────────
        s_wrap = {"maxWidth": "660px", "margin": "0 auto",
                  "fontFamily": "system-ui,-apple-system,sans-serif", "padding": "24px 16px"};
        s_card = {"background": "white", "borderRadius": "12px", "padding": "24px",
                  "marginBottom": "20px", "boxShadow": "0 2px 10px rgba(0,0,0,0.07)"};
        s_input = {"width": "100%", "padding": "10px 14px", "borderRadius": "8px",
                   "border": "1px solid #ddd", "fontSize": "14px", "boxSizing": "border-box"};
        s_btn_primary = {"padding": "14px 32px", "background": "#2ecc71", "color": "white",
                         "border": "none", "borderRadius": "10px", "cursor": "pointer",
                         "fontSize": "15px", "fontWeight": "600", "width": "100%"};
        s_btn_add = {"padding": "8px 16px", "background": "#2ecc71", "color": "white",
                     "border": "none", "borderRadius": "8px", "cursor": "pointer",
                     "fontSize": "13px", "whiteSpace": "nowrap"};
        s_btn_ghost = {"padding": "8px 18px", "background": "none", "border": "1px solid #ddd",
                       "borderRadius": "8px", "cursor": "pointer", "fontSize": "14px"};
        s_btn_expand = {"background": "none", "border": "1px solid #eee", "borderRadius": "8px",
                        "padding": "8px 16px", "cursor": "pointer", "fontSize": "13px",
                        "color": "#555", "width": "100%", "marginTop": "12px"};
        s_tag_strict = {"display": "inline-flex", "alignItems": "center", "gap": "4px",
                        "background": "#fdecea", "color": "#c0392b", "borderRadius": "20px",
                        "padding": "3px 10px 3px 12px", "fontSize": "13px",
                        "marginRight": "6px", "marginBottom": "6px"};
        s_tag_x = {"background": "none", "border": "none", "cursor": "pointer",
                   "color": "#c0392b", "fontSize": "14px", "padding": "0", "lineHeight": "1"};
        s_badge_strict = {"background": "#e74c3c", "color": "white", "borderRadius": "4px",
                          "padding": "1px 7px", "fontSize": "11px", "fontWeight": "700"};
        s_label = {"display": "block", "marginBottom": "6px", "fontSize": "13px",
                   "fontWeight": "600", "color": "#555"};
        s_pill_cal  = {"background": "#fff3e0", "color": "#e67e22", "borderRadius": "6px",
                       "padding": "4px 10px", "fontSize": "12px", "fontWeight": "600"};
        s_pill_pro  = {"background": "#e3f2fd", "color": "#1565c0", "borderRadius": "6px",
                       "padding": "4px 10px", "fontSize": "12px", "fontWeight": "600"};
        s_pill_carb = {"background": "#f3e5f5", "color": "#6a1b9a", "borderRadius": "6px",
                       "padding": "4px 10px", "fontSize": "12px", "fontWeight": "600"};
        s_pill_fat  = {"background": "#fce4ec", "color": "#ad1457", "borderRadius": "6px",
                       "padding": "4px 10px", "fontSize": "12px", "fontWeight": "600"};
        s_item_row  = {"display": "flex", "justifyContent": "space-between", "alignItems": "center",
                       "padding": "8px 12px", "background": "#f8f9fa", "borderRadius": "8px"};
        s_ing_row   = {"display": "flex", "justifyContent": "space-between", "alignItems": "center",
                       "padding": "8px 0", "borderBottom": "1px solid #f5f5f5", "fontSize": "14px"};
        s_dist_pill = {"background": "#eafaf1", "color": "#27ae60", "borderRadius": "20px",
                       "padding": "4px 12px", "fontSize": "13px", "fontWeight": "600",
                       "display": "block", "marginBottom": "4px"};
        s_price_grn = {"color": "#27ae60", "fontWeight": "700", "fontSize": "14px",
                       "whiteSpace": "nowrap", "marginLeft": "12px"};
        s_cost_pill = {"background": "#eafaf1", "color": "#27ae60", "borderRadius": "20px",
                       "padding": "5px 14px", "fontSize": "14px", "fontWeight": "700",
                       "whiteSpace": "nowrap", "marginLeft": "16px", "flexShrink": "0"};
        s_summary   = {"background": "#eafaf1", "borderRadius": "12px", "padding": "16px",
                       "marginBottom": "20px", "borderLeft": "4px solid #2ecc71"};
        s_tag_grey  = {"display": "inline-block", "background": "#f0f0f0", "color": "#555",
                       "borderRadius": "12px", "padding": "3px 10px", "fontSize": "12px",
                       "marginRight": "5px", "marginBottom": "4px"};
        s_error_box = {"background": "#fdecea", "color": "#c0392b", "borderRadius": "8px",
                       "padding": "12px 16px", "marginBottom": "16px", "fontSize": "14px"};

        # ── Tag-add helpers ───────────────────────────────────────────────────

        def add_allergy() {
            v = allergy_input.strip();
            if v and v not in allergies {
                allergies = allergies + [v];
                allergy_input = "";
            }
        }

        def add_condition() {
            v = condition_input.strip();
            if v and v not in conditions {
                conditions = conditions + [v];
                condition_input = "";
            }
        }

        def add_restriction() {
            v = restriction_input.strip();
            if v and v not in restrictions {
                restrictions = restrictions + [v];
                restriction_input = "";
            }
        }

        # ── Submit ────────────────────────────────────────────────────────────

        async def handle_submit() {
            if not location.strip() {
                error = "Please enter your location.";
                return;
            }
            error = "";
            view = "loading";
            result = await save_and_search(
                location=location.strip(),
                radius_miles=float(radius),
                allergies=allergies,
                budget=float(budget),
                calories=int(calories),
                protein_g=int(protein),
                carbs_g=int(carbs),
                fat_g=int(fat),
                macro_flex_pct=int(macro_flex),
                conditions=conditions,
                restrictions=restrictions
            );
            res = result as dict;
            if res {
                stores = res["stores"] or [];
                recipes = res["recipes"] or [];
                summary = res["summary"] or "";
                active_tab = "stores";
                view = "results";
            } else {
                error = "Search failed. Please try again.";
                view = "form";
            }
        }

        # ═════════════════════════════════════════════════════════════════════
        # LOADING VIEW
        # ═════════════════════════════════════════════════════════════════════

        if view == "loading" {
            return <div style={{"maxWidth": "660px", "margin": "100px auto", "textAlign": "center",
                                "fontFamily": "system-ui,sans-serif", "padding": "0 24px"}}>
                <div style={{"fontSize": "56px", "marginBottom": "20px"}}>🍽️</div>
                <h2 style={{"color": "#2ecc71", "fontSize": "24px", "marginBottom": "8px",
                            "fontWeight": "700"}}>Finding your perfect meals...</h2>
                <p style={{"color": "#888", "fontSize": "15px", "maxWidth": "420px",
                           "margin": "0 auto 32px", "lineHeight": "1.6"}}>
                    {"Searching stores near "} <strong>{location}</strong> {" and crafting recipes tailored to your preferences."}
                </p>
                <div style={{"display": "flex", "justifyContent": "center", "gap": "10px"}}>
                    <div style={{"width": "12px", "height": "12px", "borderRadius": "50%",
                                 "background": "#2ecc71"}} />
                    <div style={{"width": "12px", "height": "12px", "borderRadius": "50%",
                                 "background": "#2ecc71", "opacity": "0.6"}} />
                    <div style={{"width": "12px", "height": "12px", "borderRadius": "50%",
                                 "background": "#2ecc71", "opacity": "0.3"}} />
                </div>
            </div>;
        }

        # ═════════════════════════════════════════════════════════════════════
        # RESULTS VIEW
        # ═════════════════════════════════════════════════════════════════════

        if view == "results" {
            return <div style={s_wrap}>
                <div style={{"display": "flex", "justifyContent": "space-between",
                              "alignItems": "center", "marginBottom": "24px"}}>
                    <div>
                        <h1 style={{"margin": "0 0 4px", "fontSize": "24px", "color": "#1a1a1a",
                                    "fontWeight": "700"}}>🍽️ Your Food Plan</h1>
                        <p style={{"margin": "0", "color": "#888", "fontSize": "14px"}}>
                            📍 {location} · {radius} mi radius
                        </p>
                    </div>
                    <button onClick={lambda () { view = "form"; }} style={s_btn_ghost}>
                        ← New Search
                    </button>
                </div>

                {summary and <div style={s_summary}>
                    <p style={{"margin": "0", "color": "#1e8449", "fontSize": "14px",
                               "lineHeight": "1.6"}}>{summary}</p>
                </div>}

                <div style={{"display": "flex", "borderBottom": "2px solid #f0f0f0",
                              "marginBottom": "24px"}}>
                    <button
                        onClick={lambda () { active_tab = "stores"; }}
                        style={{"padding": "12px 24px", "border": "none", "background": "none",
                                "cursor": "pointer", "fontSize": "15px", "fontWeight": "600",
                                "color": ("#2ecc71" if active_tab == "stores" else "#aaa"),
                                "borderBottom": ("3px solid #2ecc71" if active_tab == "stores"
                                                 else "3px solid transparent"),
                                "marginBottom": "-2px"}}
                    >
                        🏪 Stores &amp; Items ({str(len(stores))})
                    </button>
                    <button
                        onClick={lambda () { active_tab = "recipes"; }}
                        style={{"padding": "12px 24px", "border": "none", "background": "none",
                                "cursor": "pointer", "fontSize": "15px", "fontWeight": "600",
                                "color": ("#2ecc71" if active_tab == "recipes" else "#aaa"),
                                "borderBottom": ("3px solid #2ecc71" if active_tab == "recipes"
                                                 else "3px solid transparent"),
                                "marginBottom": "-2px"}}
                    >
                        👨‍🍳 Recipes ({str(len(recipes))})
                    </button>
                </div>

                {active_tab == "stores" and <div>
                    {not stores and
                     <p style={{"color": "#bbb", "textAlign": "center", "padding": "40px 0"}}>
                         No stores found. Try increasing your radius.
                     </p>}
                    {[<div key={s.name} style={s_card}>
                        <div style={{"display": "flex", "justifyContent": "space-between",
                                      "alignItems": "flex-start", "marginBottom": "12px"}}>
                            <div>
                                <h3 style={{"margin": "0 0 4px", "fontSize": "17px",
                                           "color": "#1a1a1a"}}>{s.name}</h3>
                                <p style={{"margin": "0 0 2px", "color": "#777",
                                           "fontSize": "13px"}}>📍 {s.address}</p>
                                {s.hours and
                                 <p style={{"margin": "0", "color": "#aaa", "fontSize": "12px"}}>
                                     🕐 {s.hours}
                                 </p>}
                            </div>
                            <div style={{"textAlign": "right", "flexShrink": "0",
                                         "marginLeft": "12px"}}>
                                <span style={s_dist_pill}>{str(s.distance_miles)} mi</span>
                                <span style={{"color": "#bbb", "fontSize": "12px"}}>{s.type}</span>
                            </div>
                        </div>
                        {s.items and <div>
                            <p style={{"margin": "0 0 8px", "fontSize": "13px",
                                       "fontWeight": "600", "color": "#666",
                                       "borderTop": "1px solid #f5f5f5",
                                       "paddingTop": "12px"}}>
                                Available Items
                            </p>
                            <div style={{"display": "grid", "gap": "6px"}}>
                                {[<div key={item.name} style={s_item_row}>
                                    <div>
                                        <span style={{"fontSize": "14px", "fontWeight": "500",
                                                      "color": "#333"}}>{item.name}</span>
                                        <span style={{"marginLeft": "8px", "fontSize": "11px",
                                                      "color": "#aaa", "background": "#eee",
                                                      "padding": "2px 7px",
                                                      "borderRadius": "10px"}}>
                                            {item.category}
                                        </span>
                                        {item.notes and
                                         <span style={{"marginLeft": "6px", "fontSize": "11px",
                                                       "color": "#bbb"}}>{item.notes}</span>}
                                    </div>
                                    <span style={s_price_grn}>
                                        {"$" + str(item.estimated_price) + "/" + item.unit}
                                    </span>
                                </div> for item in s.items]}
                            </div>
                        </div>}
                    </div> for s in stores]}
                </div>}

                {active_tab == "recipes" and <div>
                    {not recipes and
                     <p style={{"color": "#bbb", "textAlign": "center", "padding": "40px 0"}}>
                         No recipes found.
                     </p>}
                    {[<div key={r.name} style={s_card}>
                        <div style={{"display": "flex", "justifyContent": "space-between",
                                      "alignItems": "flex-start", "marginBottom": "10px"}}>
                            <div style={{"flex": "1"}}>
                                <h3 style={{"margin": "0 0 4px", "fontSize": "18px",
                                           "color": "#1a1a1a"}}>{r.name}</h3>
                                <p style={{"margin": "0", "color": "#888", "fontSize": "14px",
                                           "lineHeight": "1.4"}}>{r.description}</p>
                            </div>
                            <span style={s_cost_pill}>{"$" + str(r.estimated_cost)}</span>
                        </div>

                        {r.macros_per_serving and
                         <div style={{"display": "flex", "flexWrap": "wrap", "gap": "6px",
                                       "marginBottom": "10px"}}>
                            <span style={s_pill_cal}>
                                🔥 {str(r.macros_per_serving.calories)} kcal
                            </span>
                            <span style={s_pill_pro}>
                                💪 {str(r.macros_per_serving.protein_g)}g protein
                            </span>
                            <span style={s_pill_carb}>
                                🌾 {str(r.macros_per_serving.carbs_g)}g carbs
                            </span>
                            <span style={s_pill_fat}>
                                🥑 {str(r.macros_per_serving.fat_g)}g fat
                            </span>
                         </div>}

                        <div style={{"display": "flex", "gap": "16px", "fontSize": "13px",
                                      "color": "#888", "marginBottom": "10px",
                                      "flexWrap": "wrap"}}>
                            <span>⏱ {str(r.prep_time_mins)}m prep</span>
                            <span>🔥 {str(r.cook_time_mins)}m cook</span>
                            <span>🍽 {str(r.servings)} serving(s)</span>
                            {r.macro_deviation_pct is not None and
                             <span>📊 {str(r.macro_deviation_pct)}% macro dev</span>}
                            {r.budget_deviation_pct is not None and
                             <span>💵 {str(r.budget_deviation_pct)}% budget dev</span>}
                        </div>

                        {r.tags and <div style={{"marginBottom": "12px"}}>
                            {[<span key={t} style={s_tag_grey}>{t}</span> for t in r.tags]}
                        </div>}

                        <button
                            onClick={lambda () {
                                expanded_recipe = ("" if expanded_recipe == r.name
                                                   else r.name);
                            }}
                            style={s_btn_expand}
                        >
                            {("▲ Hide Details" if expanded_recipe == r.name
                              else "▼ Ingredients & Instructions")}
                        </button>

                        {expanded_recipe == r.name and <div style={{"marginTop": "16px"}}>
                            <p style={{"fontWeight": "700", "fontSize": "14px",
                                       "marginBottom": "10px", "color": "#333"}}>
                                🛒 Ingredients
                            </p>
                            <div style={{"marginBottom": "16px"}}>
                                {[<div key={ing.item} style={s_ing_row}>
                                    <div>
                                        <span style={{"fontWeight": "500"}}>{ing.quantity}</span>
                                        <span style={{"marginLeft": "6px",
                                                      "color": "#444"}}>{ing.item}</span>
                                        <span style={{"marginLeft": "8px", "fontSize": "12px",
                                                      "color": "#aaa"}}>@ {ing.store}</span>
                                    </div>
                                    <span style={{"color": "#27ae60", "fontWeight": "600"}}>
                                        {"$" + str(ing.estimated_price)}
                                    </span>
                                </div> for ing in r.ingredients]}
                            </div>
                            <p style={{"fontWeight": "700", "fontSize": "14px",
                                       "marginBottom": "10px", "color": "#333"}}>
                                👨‍🍳 Instructions
                            </p>
                            <ol style={{"paddingLeft": "20px", "margin": "0"}}>
                                {[<li key={step}
                                      style={{"marginBottom": "8px", "fontSize": "14px",
                                              "color": "#444", "lineHeight": "1.5"}}>
                                    {step}
                                </li> for step in r.instructions]}
                            </ol>
                        </div>}
                    </div> for r in recipes]}
                </div>}
            </div>;
        }

        # ═════════════════════════════════════════════════════════════════════
        # FORM VIEW  (default)
        # ═════════════════════════════════════════════════════════════════════

        return <div style={s_wrap}>
            <div style={{"textAlign": "center", "marginBottom": "32px"}}>
                <h1 style={{"fontSize": "32px", "margin": "0 0 8px", "color": "#1a1a1a",
                            "fontWeight": "800"}}>🍽️ FoodFinder</h1>
                <p style={{"color": "#888", "margin": "0", "fontSize": "15px"}}>
                    Discover food near you · Tailored recipes · Powered by AI
                </p>
            </div>

            {error and <div style={s_error_box}>⚠️ {error}</div>}

            <div style={s_card}>
                <h2 style={{"margin": "0 0 4px", "fontSize": "16px", "color": "#222",
                            "fontWeight": "700"}}>📍 Location</h2>
                <p style={{"margin": "0 0 16px", "fontSize": "13px", "color": "#888"}}>
                    Where should we search?
                </p>
                <div style={{"marginBottom": "16px"}}>
                    <label style={s_label}>Your Address or City</label>
                    <input
                        value={location}
                        onChange={lambda (e: any) { location = e.target.value; }}
                        onKeyDown={lambda (e: any) {
                            if e.key == "Enter" { handle_submit(); }
                        }}
                        placeholder="e.g. Montreal, QC  or  123 Main St, Toronto"
                        style={s_input}
                    />
                </div>
                <div>
                    <label style={s_label}>Search Radius: {radius} miles</label>
                    <input
                        type="range"
                        min="1"
                        max="25"
                        value={radius}
                        onChange={lambda (e: any) { radius = e.target.value; }}
                        style={{"width": "100%", "accentColor": "#2ecc71", "cursor": "pointer"}}
                    />
                    <div style={{"display": "flex", "justifyContent": "space-between",
                                  "fontSize": "12px", "color": "#bbb", "marginTop": "2px"}}>
                        <span>1 mi</span>
                        <span>25 mi</span>
                    </div>
                </div>
            </div>

            <div style={s_card}>
                <h2 style={{"margin": "0 0 4px", "fontSize": "16px", "color": "#222",
                            "fontWeight": "700"}}>🚫 Restrictions</h2>
                <p style={{"margin": "0 0 20px", "fontSize": "13px", "color": "#e74c3c",
                           "fontWeight": "500"}}>
                    STRICT — the AI will never compromise these
                </p>

                <div style={{"marginBottom": "20px"}}>
                    <div style={{"display": "flex", "alignItems": "center", "gap": "8px",
                                  "marginBottom": "8px"}}>
                        <label style={{"fontWeight": "600", "fontSize": "14px",
                                       "color": "#333"}}>Allergies</label>
                        <span style={s_badge_strict}>STRICT</span>
                    </div>
                    <div style={{"display": "flex", "gap": "8px"}}>
                        <input
                            value={allergy_input}
                            onChange={lambda (e: any) { allergy_input = e.target.value; }}
                            onKeyDown={lambda (e: any) {
                                if e.key == "Enter" { add_allergy(); }
                            }}
                            placeholder="peanuts, shellfish, gluten, dairy..."
                            style={s_input}
                        />
                        <button onClick={lambda () { add_allergy(); }} style={s_btn_add}>Add</button>
                    </div>
                    <div style={{"marginTop": "8px"}}>
                        {[<span key={t} style={s_tag_strict}>
                            {t}
                            <button
                                onClick={lambda () {
                                    allergies = [x for x in allergies if x != t];
                                }}
                                style={s_tag_x}
                            >×</button>
                        </span> for t in allergies]}
                    </div>
                </div>

                <div style={{"marginBottom": "20px"}}>
                    <div style={{"display": "flex", "alignItems": "center", "gap": "8px",
                                  "marginBottom": "8px"}}>
                        <label style={{"fontWeight": "600", "fontSize": "14px",
                                       "color": "#333"}}>Medical Conditions</label>
                        <span style={s_badge_strict}>STRICT</span>
                    </div>
                    <div style={{"display": "flex", "gap": "8px"}}>
                        <input
                            value={condition_input}
                            onChange={lambda (e: any) { condition_input = e.target.value; }}
                            onKeyDown={lambda (e: any) {
                                if e.key == "Enter" { add_condition(); }
                            }}
                            placeholder="diabetes, celiac disease, hypertension..."
                            style={s_input}
                        />
                        <button onClick={lambda () { add_condition(); }} style={s_btn_add}>Add</button>
                    </div>
                    <div style={{"marginTop": "8px"}}>
                        {[<span key={t} style={s_tag_strict}>
                            {t}
                            <button
                                onClick={lambda () {
                                    conditions = [x for x in conditions if x != t];
                                }}
                                style={s_tag_x}
                            >×</button>
                        </span> for t in conditions]}
                    </div>
                </div>

                <div>
                    <div style={{"display": "flex", "alignItems": "center", "gap": "8px",
                                  "marginBottom": "8px"}}>
                        <label style={{"fontWeight": "600", "fontSize": "14px",
                                       "color": "#333"}}>Dietary Preferences</label>
                        <span style={s_badge_strict}>STRICT</span>
                    </div>
                    <div style={{"display": "flex", "gap": "8px"}}>
                        <input
                            value={restriction_input}
                            onChange={lambda (e: any) { restriction_input = e.target.value; }}
                            onKeyDown={lambda (e: any) {
                                if e.key == "Enter" { add_restriction(); }
                            }}
                            placeholder="vegan, vegetarian, halal, kosher, keto..."
                            style={s_input}
                        />
                        <button onClick={lambda () { add_restriction(); }} style={s_btn_add}>Add</button>
                    </div>
                    <div style={{"marginTop": "8px"}}>
                        {[<span key={t} style={s_tag_strict}>
                            {t}
                            <button
                                onClick={lambda () {
                                    restrictions = [x for x in restrictions if x != t];
                                }}
                                style={s_tag_x}
                            >×</button>
                        </span> for t in restrictions]}
                    </div>
                </div>
            </div>

            <div style={s_card}>
                <h2 style={{"margin": "0 0 4px", "fontSize": "16px", "color": "#222",
                            "fontWeight": "700"}}>📊 Nutritional Goals</h2>
                <p style={{"margin": "0 0 20px", "fontSize": "13px", "color": "#f39c12",
                           "fontWeight": "500"}}>
                    FLEXIBLE — AI may deviate within your tolerance to find the best match
                </p>
                <div style={{"display": "grid", "gridTemplateColumns": "1fr 1fr", "gap": "16px"}}>
                    <div>
                        <label style={s_label}>Calories (kcal / meal)</label>
                        <input type="number" value={calories} min="200" max="5000" step="50"
                               onChange={lambda (e: any) { calories = e.target.value; }}
                               style={s_input} />
                    </div>
                    <div>
                        <label style={s_label}>Budget ($ / meal)</label>
                        <input type="number" value={budget} min="1" max="200" step="0.5"
                               onChange={lambda (e: any) { budget = e.target.value; }}
                               style={s_input} />
                    </div>
                    <div>
                        <label style={s_label}>Protein (g / meal)</label>
                        <input type="number" value={protein} min="0" max="500"
                               onChange={lambda (e: any) { protein = e.target.value; }}
                               style={s_input} />
                    </div>
                    <div>
                        <label style={s_label}>Carbohydrates (g / meal)</label>
                        <input type="number" value={carbs} min="0" max="1000"
                               onChange={lambda (e: any) { carbs = e.target.value; }}
                               style={s_input} />
                    </div>
                    <div>
                        <label style={s_label}>Fat (g / meal)</label>
                        <input type="number" value={fat} min="0" max="500"
                               onChange={lambda (e: any) { fat = e.target.value; }}
                               style={s_input} />
                    </div>
                    <div>
                        <label style={s_label}>Flexibility (± %)</label>
                        <input type="number" value={macro_flex} min="0" max="50"
                               onChange={lambda (e: any) { macro_flex = e.target.value; }}
                               style={s_input} />
                    </div>
                </div>
                <p style={{"margin": "14px 0 0", "fontSize": "12px", "color": "#bbb",
                           "lineHeight": "1.5"}}>
                    Flexibility applies to calories, macros, and budget.
                    Allergies, medical conditions, and dietary preferences are always 0% flexible.
                </p>
            </div>

            <button onClick={lambda () { handle_submit(); }} style={s_btn_primary}>
                🔍 Find Food &amp; Recipes
            </button>
            <div style={{"height": "48px"}} />
        </div>;
    }

