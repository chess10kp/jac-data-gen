"""Jac-authored browser shell that boots the Electron browser runtime."""

import from 'react' { useEffect as reactUseEffect }
import from '../../../../generated/shell_runtime.mjs' { bootstrapBrowserShell }


def:pub BrowserShell() -> JsxElement {
    reactUseEffect(lambda { bootstrapBrowserShell(); }, []);

    return
        <div className="app-shell">
            <header className="browser-chrome">
                <div className="drag-region" aria-hidden="true"></div>
                <div className="tab-strip">
                    <div className="chrome-brand" aria-hidden="true">
                        <span className="brand-mark"></span>
                        <span className="brand-copy">Jac Browser</span>
                    </div>
                    <div id="tabList" className="tab-list"></div>
                    <button
                        id="newTabBtn"
                        className="new-tab-btn"
                        type="button"
                        title="New Tab"
                        aria-label="New Tab"
                    >
                        <svg viewBox="0 0 20 20" aria-hidden="true">
                            <path
                                d="M10 4.25a.75.75 0 0 1 .75.75v4.25H15a.75.75 0 0 1 0 1.5h-4.25V15a.75.75 0 0 1-1.5 0v-4.25H5a.75.75 0 0 1 0-1.5h4.25V5a.75.75 0 0 1 .75-.75Z"
                                fill="currentColor"
                            />
                        </svg>
                    </button>
                    <div className="window-controls">
                        <button
                            id="minBtn"
                            className="window-btn"
                            type="button"
                            title="Minimize"
                        >
                            -
                        </button>
                        <button
                            id="maxBtn"
                            className="window-btn"
                            type="button"
                            title="Maximize"
                        >
                            []
                        </button>
                        <button
                            id="closeBtn"
                            className="window-btn danger"
                            type="button"
                            title="Close"
                        >
                            X
                        </button>
                    </div>
                </div>
                <div className="toolbar">
                    <div className="nav-group">
                        <button
                            id="homeBtn"
                            className="icon-btn"
                            type="button"
                            title="Home"
                            aria-label="Home"
                        >
                            <svg viewBox="0 0 20 20" aria-hidden="true">
                                <path
                                    d="M10 3.5 3.75 8.8v6.45c0 .41.34.75.75.75h3.5v-4.4c0-.41.34-.75.75-.75h2.5c.41 0 .75.34.75.75V16h3.5c.41 0 .75-.34.75-.75V8.8L10 3.5Z"
                                    fill="currentColor"
                                />
                            </svg>
                        </button>
                        <button
                            id="backBtn"
                            className="icon-btn"
                            type="button"
                            title="Back"
                            aria-label="Back"
                        >
                            <svg viewBox="0 0 20 20" aria-hidden="true">
                                <path
                                    d="M11.75 4.75 6.5 10l5.25 5.25 1.06-1.06L8.62 10l4.19-4.19-1.06-1.06Z"
                                    fill="currentColor"
                                />
                            </svg>
                        </button>
                        <button
                            id="forwardBtn"
                            className="icon-btn"
                            type="button"
                            title="Forward"
                            aria-label="Forward"
                        >
                            <svg viewBox="0 0 20 20" aria-hidden="true">
                                <path
                                    d="M8.25 15.25 13.5 10 8.25 4.75 7.19 5.81 11.38 10l-4.19 4.19 1.06 1.06Z"
                                    fill="currentColor"
                                />
                            </svg>
                        </button>
                        <button
                            id="reloadBtn"
                            className="icon-btn"
                            type="button"
                            title="Reload"
                            aria-label="Reload"
                        >
                            <svg viewBox="0 0 20 20" aria-hidden="true">
                                <path
                                    d="M14.96 8A5 5 0 1 0 15 12h-1.6A3.5 3.5 0 1 1 12.94 8H10V6.5h5V11h-1.5V8Z"
                                    fill="currentColor"
                                />
                            </svg>
                        </button>
                    </div>
                    <form id="navForm" className="omnibox-wrap">
                        <span id="siteBadge" className="site-badge" data-state="secure">
                            Secure
                        </span>
                        <input
                            id="addressInput"
                            className="address-input"
                            type="text"
                            placeholder="Search or enter address"
                            autocomplete="off"
                            spellcheck="false"
                        />
                        <button
                            id="goBtn"
                            className="go-btn"
                            type="submit"
                            aria-label="Go"
                        >
                            <svg viewBox="0 0 20 20" aria-hidden="true">
                                <path
                                    d="M5 10h8.19l-3.1 3.1 1.06 1.06L16.06 9.25 11.15 4.34 10.09 5.4l3.1 3.1H5V10Z"
                                    fill="currentColor"
                                />
                            </svg>
                        </button>
                    </form>
                    <div className="toolbar-actions">
                        <button
                            id="showBrowserViewBtn"
                            className="toolbar-pill"
                            type="button"
                            title="Show Browser View"
                            aria-pressed="true"
                        >
                            Browser
                        </button>
                        <button
                            id="showHelpersViewBtn"
                            className="toolbar-pill"
                            type="button"
                            title="Show Helpers View"
                            aria-pressed="false"
                        >
                            Helpers
                        </button>
                        <button
                            id="toggleLayersBtn"
                            className="toolbar-pill"
                            type="button"
                            title="Close Tasks Panel"
                            aria-pressed="true"
                            aria-expanded="true"
                        >
                            TASKS
                        </button>
                        <div className="profile-chip" aria-hidden="true">
                            <span className="profile-avatar">J</span>
                            <span className="profile-name">Workspace</span>
                        </div>
                    </div>
                </div>
                <div className="bookmark-bar">
                    <button
                        className="bookmark-item"
                        type="button"
                        data-nav-url="https://jaclang.org/"
                    >
                        <span className="bookmark-favicon jac"></span>
                        <span>Jac Lang</span>
                    </button>
                    <button
                        className="bookmark-item"
                        type="button"
                        data-nav-url="https://docs.jac-lang.org/"
                    >
                        <span className="bookmark-favicon docs"></span>
                        <span>Docs</span>
                    </button>
                    <button
                        className="bookmark-item"
                        type="button"
                        data-nav-url="https://github.com/"
                    >
                        <span className="bookmark-favicon github"></span>
                        <span>GitHub</span>
                    </button>
                    <button
                        className="bookmark-item"
                        type="button"
                        data-nav-url="https://platform.openai.com/docs/overview"
                    >
                        <span className="bookmark-favicon openai"></span>
                        <span>OpenAI</span>
                    </button>
                    <button
                        className="bookmark-item"
                        type="button"
                        data-nav-url="https://www.electronjs.org/docs/latest/"
                    >
                        <span className="bookmark-favicon electron"></span>
                        <span>Electron</span>
                    </button>
                    <button
                        className="bookmark-item"
                        type="button"
                        data-nav-url="https://www.google.com/"
                    >
                        <span className="bookmark-favicon search"></span>
                        <span>Google</span>
                    </button>
                    <div className="bookmark-spacer"></div>
                    <button className="bookmark-folder" type="button">
                        All Bookmarks
                    </button>
                </div>
                <div className="progress-track">
                    <div id="progressBar" className="progress-bar"></div>
                </div>
            </header>
            <div id="shellContent" className="shell-content">
                <aside id="layerPanel" className="layer-panel">
                    <div className="layer-panel-header task-panel-header">
                        <div
                            style={{
                                "display": "flex",
                                "flexDirection": "column",
                                "gap": "6px",
                                "minWidth": "0"
                            }}
                        >
                            <div className="layer-panel-kicker">Quick workflow</div>
                            <div className="layer-panel-title">TASKS</div>
                            <div
                                style={{
                                    "color": "#526885",
                                    "fontSize": "12px",
                                    "lineHeight": "1.6"
                                }}
                            >
                                Record a task, add context, and generate a saved helper here. Use Run for one-off launches and Helpers for deeper editing, inspection, and history.
                            </div>
                        </div>
                        <button
                            id="tasksPanelOpenHelpersBtn"
                            className="layer-btn task-panel-secondary-btn"
                            type="button"
                        >
                            Open Helpers
                        </button>
                    </div>
                    <div
                        className="task-panel-tabs"
                        role="tablist"
                        aria-label="Task panel modes"
                    >
                        <button
                            id="tasksCreateTabBtn"
                            className="task-panel-tab"
                            type="button"
                            role="tab"
                            aria-selected="true"
                            aria-controls="tasksCreatePanel"
                        >
                            Create
                        </button>
                        <button
                            id="tasksRunTabBtn"
                            className="task-panel-tab"
                            type="button"
                            role="tab"
                            aria-selected="false"
                            aria-controls="tasksRunPanel"
                        >
                            Run
                        </button>
                    </div>
                    <section
                        id="tasksCreatePanel"
                        className="task-panel-section"
                        role="tabpanel"
                        aria-labelledby="tasksCreateTabBtn"
                    >
                        <div className="task-panel-card">
                            <div
                                style={{
                                    "display": "flex",
                                    "flexDirection": "column",
                                    "gap": "4px"
                                }}
                            >
                                <div
                                    className="layer-state-label"
                                    style={{"fontSize": "11px"}}
                                >
                                    Create task
                                </div>
                                <div
                                    style={{
                                        "color": "#1d2a3e",
                                        "fontSize": "16px",
                                        "fontWeight": "800"
                                    }}
                                >
                                    Record task flow
                                </div>
                                <div
                                    style={{
                                        "color": "#526885",
                                        "fontSize": "12px",
                                        "lineHeight": "1.6"
                                    }}
                                >
                                    Task creation starts by recording the workflow in the browser, then adding extra context before generation.
                                </div>
                            </div>
                            <div
                                id="taskCreateRecordingState"
                                className="task-create-state"
                            >
                                <div className="task-create-state-copy">
                                    Click Start, perform the task in the browser, then stop recording so you can add context for generation.
                                </div>
                                <div
                                    id="taskCreateSessionMeta"
                                    className="task-create-session-meta"
                                >
                                    No recording captured yet.
                                </div>
                            </div>
                            <div className="layer-panel-actions task-panel-actions">
                                <button
                                    id="taskPanelRecordBtn"
                                    className="layer-btn task-panel-primary-action"
                                    type="button"
                                >
                                    Start
                                </button>
                            </div>
                            <div
                                id="taskCreateContextPanel"
                                className="task-create-context-panel"
                                style={{"display": "none"}}
                            >
                                <div
                                    style={{
                                        "display": "flex",
                                        "flexDirection": "column",
                                        "gap": "6px"
                                    }}
                                >
                                    <label
                                        className="layer-state-label"
                                        htmlFor="taskCreateContextInput"
                                        style={{"fontSize": "11px"}}
                                    >
                                        Extra context
                                    </label>
                                    <textarea
                                        id="taskCreateContextInput"
                                        className="task-panel-textarea"
                                        rows={5}
                                        placeholder="Add any extra instructions, preferences, or success criteria for the saved task."
                                        spellcheck="false"
                                    ></textarea>
                                </div>
                                <div className="task-panel-note">
                                    Generate Task uses the recorded trace plus this added context to create the local saved helper for this demo session.
                                </div>
                                <div className="layer-panel-actions task-panel-actions">
                                    <button
                                        id="taskPanelGenerateBtn"
                                        className="layer-btn"
                                        type="button"
                                    >
                                        Generate Task
                                    </button>
                                </div>
                            </div>
                        </div>
                    </section>
                    <section
                        id="tasksRunPanel"
                        className="task-panel-section"
                        role="tabpanel"
                        aria-labelledby="tasksRunTabBtn"
                        style={{"display": "none"}}
                    >
                        <div className="task-panel-card task-panel-run-layout">
                            <div className="task-panel-run-scroll">
                                <div
                                    style={{
                                        "display": "flex",
                                        "flexDirection": "column",
                                        "gap": "4px"
                                    }}
                                >
                                    <div
                                        className="layer-state-label"
                                        style={{"fontSize": "11px"}}
                                    >
                                        Run task
                                    </div>
                                    <div
                                        style={{
                                            "color": "#1d2a3e",
                                            "fontSize": "16px",
                                            "fontWeight": "800"
                                        }}
                                    >
                                        Saved tasks and helpers
                                    </div>
                                    <div
                                        style={{
                                            "color": "#526885",
                                            "fontSize": "12px",
                                            "lineHeight": "1.6"
                                        }}
                                    >
                                        Pick a saved task, add optional run-only guidance, and launch it without changing the saved helper.
                                    </div>
                                </div>
                                <div id="helperList" className="task-panel-helper-list">
                                    No saved tasks yet. Use Create to make one quickly, or open Helpers for deeper management.
                                </div>
                                <div className="task-panel-selection">
                                    <div
                                        style={{
                                            "display": "flex",
                                            "flexDirection": "column",
                                            "gap": "4px"
                                        }}
                                    >
                                        <div
                                            className="layer-state-label"
                                            style={{"fontSize": "11px"}}
                                        >
                                            Selected task
                                        </div>
                                        <div
                                            id="taskRunSelectedName"
                                            className="task-panel-selection-title"
                                        >
                                            No task selected
                                        </div>
                                        <div
                                            id="taskRunSelectedMeta"
                                            className="task-panel-selection-meta"
                                        >
                                            Choose a saved task from the list above, or create one in this panel.
                                        </div>
                                        <div
                                            id="taskRunSelectedGoal"
                                            className="task-panel-selection-goal"
                                        >
                                            Saved instructions will appear here before you run.
                                        </div>
                                    </div>
                                    <div
                                        style={{
                                            "display": "flex",
                                            "flexDirection": "column",
                                            "gap": "6px"
                                        }}
                                    >
                                        <label
                                            className="layer-state-label"
                                            htmlFor="taskRunOverrideInput"
                                            style={{"fontSize": "11px"}}
                                        >
                                            Run-specific guidance
                                        </label>
                                        <textarea
                                            id="taskRunOverrideInput"
                                            className="task-panel-textarea task-panel-override"
                                            rows={4}
                                            placeholder="Optional: for this run only, focus on release notes from the last 24 hours."
                                            spellcheck="false"
                                        ></textarea>
                                    </div>
                                    <div className="task-panel-note">
                                        This text affects only the current run. The saved task keeps its original instructions unless you edit it from Helpers.
                                    </div>
                                    <div
                                        className="layer-panel-actions task-panel-actions"
                                    >
                                        <button
                                            id="taskPanelRunBtn"
                                            className="layer-btn"
                                            type="button"
                                        >
                                            Run Task
                                        </button>
                                        <button
                                            id="taskPanelRunClearBtn"
                                            className="layer-btn"
                                            type="button"
                                        >
                                            Clear Note
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </section>
                </aside>
                <div className="shell-main-stage">
                    <main id="viewport" className="viewport"></main>
                    <section
                        id="helpersPage"
                        aria-label="Helpers"
                        style={{
                            "display": "none",
                            "flex": "1 1 auto",
                            "minHeight": "0",
                            "padding": "20px 18px 18px",
                            "boxSizing": "border-box",
                            "background": "linear-gradient(180deg, #f8fbff 0%, #eef4ff 100%)",
                            "overflow": "auto"
                        }}
                    >
                        <div
                            style={{
                                "display": "flex",
                                "flexDirection": "column",
                                "gap": "16px",
                                "minHeight": "100%"
                            }}
                        >
                            <div
                                style={{
                                    "display": "flex",
                                    "alignItems": "center",
                                    "justifyContent": "space-between",
                                    "gap": "16px",
                                    "padding": "20px 22px",
                                    "borderRadius": "24px",
                                    "border": "1px solid rgba(88, 116, 173, 0.12)",
                                    "background": "rgba(255, 255, 255, 0.92)",
                                    "boxShadow": "0 14px 34px rgba(52, 81, 126, 0.08)"
                                }}
                            >
                                <div
                                    style={{
                                        "display": "flex",
                                        "flexDirection": "column",
                                        "gap": "6px"
                                    }}
                                >
                                    <div
                                        className="layer-state-label"
                                        style={{"fontSize": "11px"}}
                                    >
                                        Local demo workspace
                                    </div>
                                    <div
                                        style={{
                                            "color": "#183154",
                                            "fontSize": "28px",
                                            "fontWeight": "800",
                                            "letterSpacing": "-0.03em"
                                        }}
                                    >
                                        Helpers
                                    </div>
                                    <div
                                        style={{
                                            "color": "#526885",
                                            "fontSize": "13px",
                                            "lineHeight": "1.6",
                                            "maxWidth": "720px"
                                        }}
                                    >
                                        Create, edit, inspect, and review saved helpers here. Run them later from TASKS whenever you want to reuse an automation.
                                    </div>
                                </div>
                                <button
                                    id="helpersPageCreateBtn"
                                    className="layer-btn"
                                    type="button"
                                    style={{"minWidth": "148px"}}
                                >
                                    Create Helper
                                </button>
                            </div>
                            <section
                                id="helperBuilderPanel"
                                style={{
                                    "display": "none",
                                    "flexDirection": "column",
                                    "gap": "12px",
                                    "padding": "18px",
                                    "borderRadius": "24px",
                                    "border": "1px solid rgba(88, 116, 173, 0.14)",
                                    "background": "linear-gradient(180deg, rgba(255, 255, 255, 0.98) 0%, rgba(237, 244, 255, 0.98) 100%)",
                                    "boxShadow": "0 16px 30px rgba(48, 77, 128, 0.08)"
                                }}
                            >
                                <div
                                    style={{
                                        "display": "flex",
                                        "flexDirection": "column",
                                        "gap": "4px"
                                    }}
                                >
                                    <div className="layer-state-label">
                                        Create Helper
                                    </div>
                                    <div
                                        style={{
                                            "color": "#1d2a3e",
                                            "fontSize": "18px",
                                            "fontWeight": "800"
                                        }}
                                    >
                                        Saved Task Builder
                                    </div>
                                    <div
                                        style={{
                                            "color": "#526885",
                                            "fontSize": "12px",
                                            "lineHeight": "1.6"
                                        }}
                                    >
                                        Add a reusable helper here, then launch it later from TASKS. Saved helpers sync with the backend for this demo.
                                    </div>
                                </div>
                                <div
                                    style={{
                                        "display": "grid",
                                        "gridTemplateColumns": "repeat(auto-fit, minmax(220px, 1fr))",
                                        "gap": "12px"
                                    }}
                                >
                                    <div
                                        style={{
                                            "display": "flex",
                                            "flexDirection": "column",
                                            "gap": "6px"
                                        }}
                                    >
                                        <label
                                            className="layer-state-label"
                                            htmlFor="helperNameInput"
                                            style={{"fontSize": "11px"}}
                                        >
                                            Name
                                        </label>
                                        <input
                                            id="helperNameInput"
                                            type="text"
                                            placeholder="Morning Brief"
                                            spellcheck="false"
                                            style={{
                                                "width": "100%",
                                                "padding": "11px 12px",
                                                "borderRadius": "14px",
                                                "border": "1px solid rgba(88, 116, 173, 0.14)",
                                                "background": "#ffffff",
                                                "boxSizing": "border-box",
                                                "color": "#1f345a",
                                                "fontSize": "14px",
                                                "fontWeight": "600"
                                            }}
                                        />
                                    </div>
                                    <div
                                        style={{
                                            "display": "flex",
                                            "flexDirection": "column",
                                            "gap": "6px"
                                        }}
                                    >
                                        <label
                                            className="layer-state-label"
                                            htmlFor="helperFrequencySelect"
                                            style={{"fontSize": "11px"}}
                                        >
                                            How often
                                        </label>
                                        <select
                                            id="helperFrequencySelect"
                                            style={{
                                                "width": "100%",
                                                "padding": "11px 12px",
                                                "borderRadius": "14px",
                                                "border": "1px solid rgba(88, 116, 173, 0.14)",
                                                "background": "#ffffff",
                                                "boxSizing": "border-box",
                                                "color": "#1f345a",
                                                "fontSize": "14px",
                                                "fontWeight": "600"
                                            }}
                                        >
                                            <option value="once">Just once</option>
                                            <option value="browser_open">
                                                On browser open
                                            </option>
                                            <option value="daily">Daily</option>
                                            <option value="weekly">Weekly</option>
                                        </select>
                                    </div>
                                </div>
                                <div
                                    style={{
                                        "display": "flex",
                                        "flexDirection": "column",
                                        "gap": "6px"
                                    }}
                                >
                                    <label
                                        className="layer-state-label"
                                        htmlFor="helperGoalInput"
                                        style={{"fontSize": "11px"}}
                                    >
                                        What do you want it to do
                                    </label>
                                    <textarea
                                        id="helperGoalInput"
                                        rows={6}
                                        placeholder="Summarize the newest Jac and Electron updates I should know before I start work."
                                        spellcheck="false"
                                        style={{
                                            "width": "100%",
                                            "minHeight": "136px",
                                            "padding": "12px 14px",
                                            "borderRadius": "16px",
                                            "border": "1px solid rgba(88, 116, 173, 0.14)",
                                            "background": "#ffffff",
                                            "boxSizing": "border-box",
                                            "color": "#1f345a",
                                            "fontSize": "14px",
                                            "fontWeight": "600",
                                            "lineHeight": "1.6",
                                            "resize": "vertical"
                                        }}
                                    ></textarea>
                                </div>
                                <div
                                    className="layer-panel-actions"
                                    style={{"marginBottom": "0", "maxWidth": "280px"}}
                                >
                                    <button
                                        id="helperCreateBtn"
                                        className="layer-btn"
                                        type="button"
                                    >
                                        Create
                                    </button>
                                    <button
                                        id="helperCancelBtn"
                                        className="layer-btn"
                                        type="button"
                                    >
                                        Cancel
                                    </button>
                                </div>
                            </section>
                            <div
                                style={{
                                    "display": "grid",
                                    "gridTemplateColumns": "minmax(260px, 320px) minmax(0, 1fr)",
                                    "gap": "16px",
                                    "alignItems": "stretch",
                                    "minHeight": "0",
                                    "flex": "1 1 auto"
                                }}
                            >
                                <section
                                    style={{
                                        "display": "flex",
                                        "flexDirection": "column",
                                        "gap": "12px",
                                        "minHeight": "0",
                                        "padding": "18px",
                                        "borderRadius": "24px",
                                        "border": "1px solid rgba(88, 116, 173, 0.12)",
                                        "background": "rgba(255, 255, 255, 0.94)",
                                        "boxShadow": "0 14px 30px rgba(52, 81, 126, 0.07)"
                                    }}
                                >
                                    <div>
                                        <div
                                            className="layer-state-label"
                                            style={{"fontSize": "11px"}}
                                        >
                                            All helpers
                                        </div>
                                        <div
                                            style={{
                                                "marginTop": "4px",
                                                "color": "#1d2a3e",
                                                "fontSize": "18px",
                                                "fontWeight": "800"
                                            }}
                                        >
                                            Helper List
                                        </div>
                                    </div>
                                    <div
                                        id="helpersPageList"
                                        style={{
                                            "display": "flex",
                                            "flexDirection": "column",
                                            "gap": "10px",
                                            "minHeight": "0"
                                        }}
                                    >
                                        No helpers yet. Create one to populate this workspace.
                                    </div>
                                </section>
                                <div
                                    style={{
                                        "display": "flex",
                                        "flexDirection": "column",
                                        "gap": "16px",
                                        "minHeight": "0"
                                    }}
                                >
                                    <section
                                        style={{
                                            "display": "flex",
                                            "flexDirection": "column",
                                            "gap": "12px",
                                            "padding": "18px",
                                            "borderRadius": "24px",
                                            "border": "1px solid rgba(88, 116, 173, 0.12)",
                                            "background": "rgba(255, 255, 255, 0.94)",
                                            "boxShadow": "0 14px 30px rgba(52, 81, 126, 0.07)"
                                        }}
                                    >
                                        <div>
                                            <div
                                                className="layer-state-label"
                                                style={{"fontSize": "11px"}}
                                            >
                                                Selected helper
                                            </div>
                                            <div
                                                style={{
                                                    "marginTop": "4px",
                                                    "color": "#1d2a3e",
                                                    "fontSize": "18px",
                                                    "fontWeight": "800"
                                                }}
                                            >
                                                Detail
                                            </div>
                                        </div>
                                        <div
                                            id="helpersPageDetail"
                                            style={{
                                                "display": "flex",
                                                "flexDirection": "column",
                                                "gap": "12px"
                                            }}
                                        >
                                            Select a helper to inspect its instructions, schedule, and latest run state.
                                        </div>
                                    </section>
                                    <section
                                        style={{
                                            "display": "flex",
                                            "flexDirection": "column",
                                            "gap": "12px",
                                            "padding": "18px",
                                            "borderRadius": "24px",
                                            "border": "1px solid rgba(88, 116, 173, 0.12)",
                                            "background": "rgba(255, 255, 255, 0.94)",
                                            "boxShadow": "0 14px 30px rgba(52, 81, 126, 0.07)"
                                        }}
                                    >
                                        <div>
                                            <div
                                                className="layer-state-label"
                                                style={{"fontSize": "11px"}}
                                            >
                                                Recent runs
                                            </div>
                                            <div
                                                style={{
                                                    "marginTop": "4px",
                                                    "color": "#1d2a3e",
                                                    "fontSize": "18px",
                                                    "fontWeight": "800"
                                                }}
                                            >
                                                Results
                                            </div>
                                        </div>
                                        <div
                                            id="helpersPageResults"
                                            style={{
                                                "display": "flex",
                                                "flexDirection": "column",
                                                "gap": "10px"
                                            }}
                                        >
                                            Run a helper to capture its latest results here.
                                        </div>
                                    </section>
                                </div>
                            </div>
                        </div>
                    </section>
                </div>
            </div>
        </div>;
}
