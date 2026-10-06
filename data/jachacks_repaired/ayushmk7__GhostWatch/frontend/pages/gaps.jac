import from "@jac/runtime" { Link }
import from ..components.GraphStateProvider { useGraphState }
import from ..components.AmbientBackground { AmbientBackground }


def:pub page() -> JsxElement {
    gs: any = useGraphState();
    graphPayload: any = None;
    if gs and ("report" in gs) {
        graphPayload = gs["report"];
    }
    loading: any = True;
    if gs and ("loading" in gs) {
        loading = gs["loading"];
    }
    err: any = None;
    if gs and ("error" in gs) {
        err = gs["error"];
    }
    gap: any = None;
    if graphPayload and ("latest_gap_analysis" in graphPayload) {
        gap = graphPayload["latest_gap_analysis"];
    }
    suggestions: any = [];
    if gap and ("suggestions" in gap) {
        suggestions = gap["suggestions"];
    }
    mergeSha = "";
    if gap and ("merge_commit_sha" in gap) {
        mergeSha = str(gap["merge_commit_sha"]);
    }
    createdAt = "";
    if gap and ("created_at" in gap) {
        createdAt = str(gap["created_at"]);
    }

    return
        <div className="gw-page">
            <AmbientBackground screen="app"/>
            <div className="gw-page-inner gw-page-inner--app">
                <div
                    className="gw-main-grid gw-main-grid--single gw-fade-up gw-stagger-3"
                >
                    <main className="gw-main-column">
                        <section className="gw-table-panel gw-glass-panel">
                            <h2 className="gw-table-panel-title">Gaps</h2>
                            {loading
                                and <p className="gw-repo-connect-lede">Loading…</p>}
                            {not loading
                                and err
                                and <p className="gw-repo-connect-lede">
                                    Graph state unavailable.
                                </p>}
                            {not loading
                                and not err
                                and not gap
                                and <p className="gw-repo-connect-lede">
                                    No gap analysis in the current snapshot.
                                </p>}
                            {not loading
                                and not err
                                and gap
                                and <div>
                                    <p className="gw-repo-connect-lede">
                                        Merge{" "}{mergeSha}{" · "}{createdAt}
                                    </p>
                                    <table className="gw-data-table">
                                        <thead>
                                            <tr>
                                                <th>Title</th>
                                                <th>Description</th>
                                                <th>Difficulty</th>
                                                <th>File</th>
                                                <th>Type</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {[
                                                <tr
                                                    key={(
                                                        str(row["file_path"])
                                                            if row
                                                                and ("file_path" in row)
                                                            else ""
                                                    )
                                                        + (
                                                            str(row["title"])
                                                                if row
                                                                    and ("title" in row)
                                                                else ""
                                                        )}
                                                >
                                                    <td>
                                                        {str(row["title"])
                                                            if row and ("title" in row)
                                                            else ""}
                                                    </td>
                                                    <td>
                                                        {str(row["description"])
                                                            if row
                                                                and (
                                                                    "description" in row
                                                                )
                                                            else ""}
                                                    </td>
                                                    <td>
                                                        {str(row["difficulty"])
                                                            if row
                                                                and (
                                                                    "difficulty" in row
                                                                )
                                                            else ""}
                                                    </td>
                                                    <td>
                                                        {str(row["file_path"])
                                                            if row
                                                                and ("file_path" in row)
                                                            else ""}
                                                    </td>
                                                    <td>
                                                        {str(row["suggestion_type"])
                                                            if row
                                                                and (
                                                                    "suggestion_type"
                                                                    in row
                                                                )
                                                            else ""}
                                                    </td>
                                                </tr> for row in suggestions
                                            ]}
                                        </tbody>
                                    </table>
                                </div>}
                            <p style={{"marginTop": "16px"}}>
                                <Link to="/start" className="gw-role-back">Back</Link>
                            </p>
                        </section>
                    </main>
                </div>
            </div>
        </div>;
}
