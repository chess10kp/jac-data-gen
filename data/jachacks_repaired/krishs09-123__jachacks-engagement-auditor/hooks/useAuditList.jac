import from ..services.audits { list_audit_runs }
import from ..services.models { AuditListItem }

obj AuditListState {
    has audits: list[AuditListItem] = [];
    has loading: bool = True;
    has error: str = "";
    has refresh: any = None;
}

def:pub useAuditList(sort_by: str) -> AuditListState {
    has audits: list[AuditListItem] = [];
    has loading: bool = True;
    has error: str = "";

    async def refresh(next_sort: str) -> None {
        loading = True;
        error = "";
        try {
            loaded_audits: list[AuditListItem] = [];
            loaded_audits = await list_audit_runs(next_sort);
            audits = loaded_audits;
        } except Exception as e {
            error = "Could not load audits: " + str(e);
        }
        loading = False;
    }

    async can with entry {
        await refresh(sort_by);
    }

    return AuditListState(
        audits=audits,
        loading=loading,
        error=error,
        refresh=refresh,
    );
}
