node Sanctions {
    has user_id: str;
    has user_name: str;
    has reason: str;
    has mod_id: str;
    has mod_name: str;
    has s_type: str;
    has date: str;
}

node DB_User {
    has user_id: str;
    has user_name: str;
    has user_perms: list[str] = [];
    has user_roles: list[str] = [];
}

node DB_Roles {
    has role_id: str;
    has role_name: str;
    has role_perms: list[str] = [];
}

node Ticket {
    has ticket_id: str;
    has ticket_user: str;
    has ticket_status: str;
    has allowed_users: list[str] = [];
}

node Server {
    has srv_id: str;
    has name: str;
    has owner_id: int;
    has member_count: int;
    has sanctions: list[str] = [];
    has role: list[str] = [];
    has user: list[str] = [];
    has tickets: list[str] = [];
}

walker:pub create_DB_Roles {
    has role_id: str; has role_name: str; has role_perms: list[str] = [];
    can go with Root entry { new = here ++> DB_Roles(role_id=self.role_id, role_name=self.role_name, role_perms=self.role_perms); report new; }
}
walker:pub list_DB_Roles {
    can go with Root entry { report [-->[?:DB_Roles]]; }
}
walker:pub update_DB_Roles {
    has val: str;
    can go with DB_Roles entry { here.role_name = self.val; report here; }
}
walker:pub delete_DB_Roles {
    can go with DB_Roles entry { del here; report "deleted"; }
}

# FARM sample: fullstack layer on top of behavior-gated CRUD walkers.
# Source: Axiaaa/Iris utils/db.py — DB_Roles node lifted from Mongo ODM.
def:pub app() -> JsxElement {
        has roles: list[DB_Roles] = [];
        has role_id: str = "";
        has role_name: str = "";
        has edit_name: str = "";
        has editing: str | None = None;

        async def reload() -> None {
            result = root spawn list_DB_Roles();
            if result.reports and len(result.reports) > 0 {
                roles = result.reports[0];
            }
        }

        async can with entry {
            await reload();
        }

        async def handle_create() -> None {
            if not role_id.strip() or not role_name.strip() {
                return;
            }
            result = root spawn create_DB_Roles(
                role_id=role_id.strip(),
                role_name=role_name.strip(),
                role_perms=[]
            );
            if result.reports and len(result.reports) > 0 {
                roles = roles + [result.reports[0]];
            }
            role_id = "";
            role_name = "";
        }

        async def handle_update(role: DB_Roles) -> None {
            if not edit_name.strip() {
                return;
            }
            result = role spawn update_DB_Roles(val=edit_name.strip());
            if result.reports and len(result.reports) > 0 {
                updated = result.reports[0];
                roles = [updated if jid(r) == jid(role) else r for r in roles];
            }
            editing = None;
            edit_name = "";
        }

        async def handle_delete(role: DB_Roles) -> None {
            role spawn delete_DB_Roles();
            roles = [r for r in roles if jid(r) != jid(role)];
        }

        def start_edit(role: DB_Roles) -> None {
            editing = role.role_id;
            edit_name = role.role_name;
        }

        def cancel_edit() -> None {
            editing = None;
            edit_name = "";
        }

        return <div className="p-6 max-w-2xl mx-auto font-sans">
            <h1 className="text-2xl font-bold mb-1">Iris Role Admin</h1>
            <p className="text-sm text-gray-500 mb-6">
                FARM sample — ODM lift + gated walkers + client
            </p>

            <section className="mb-8 p-4 border rounded-lg bg-white shadow-sm">
                <h2 className="text-lg font-semibold mb-3">Create role</h2>
                <div className="flex gap-2">
                    <input
                        className="flex-1 border rounded px-3 py-2"
                        placeholder="role_id"
                        value={role_id}
                        onChange={lambda (e: ChangeEvent) { role_id = e.target.value; }}
                    />
                    <input
                        className="flex-1 border rounded px-3 py-2"
                        placeholder="role_name"
                        value={role_name}
                        onChange={lambda (e: ChangeEvent) { role_name = e.target.value; }}
                    />
                    <button
                        className="px-4 py-2 bg-blue-600 text-white rounded"
                        onClick={handle_create}
                    >
                        Add
                    </button>
                </div>
            </section>

            <section className="p-4 border rounded-lg bg-white shadow-sm">
                <div className="flex justify-between items-center mb-3">
                    <h2 className="text-lg font-semibold">Roles ({len(roles)})</h2>
                    <button
                        className="text-sm text-blue-600"
                        onClick={reload}
                    >
                        Refresh
                    </button>
                </div>
                {if len(roles) == 0 {
                    <p className="text-gray-400 text-center py-6">No roles yet.</p>
                }}
                {for role in roles {
                    <div
                        key={jid(role)}
                        className="flex items-center gap-3 py-3 border-b last:border-b-0"
                    >
                        {if editing == role.role_id {
                            <input
                                className="flex-1 border rounded px-2 py-1"
                                value={edit_name}
                                onChange={lambda (e: ChangeEvent) { edit_name = e.target.value; }}
                            />
                            <button
                                className="px-3 py-1 bg-green-600 text-white rounded text-sm"
                                onClick={lambda { handle_update(role); }}
                            >
                                Save
                            </button>
                            <button
                                className="px-3 py-1 border rounded text-sm"
                                onClick={cancel_edit}
                            >
                                Cancel
                            </button>
                        } else {
                            <div className="flex-1">
                                <span className="font-mono text-sm text-gray-500">{role.role_id}</span>
                                <span className="mx-2">—</span>
                                <span>{role.role_name}</span>
                                {if len(role.role_perms) > 0 {
                                    <span className="ml-2 text-xs text-gray-400">
                                        ({len(role.role_perms)} perms)
                                    </span>
                                }}
                            </div>
                            <button
                                className="px-3 py-1 border rounded text-sm"
                                onClick={lambda { start_edit(role); }}
                            >
                                Edit
                            </button>
                            <button
                                className="px-3 py-1 bg-red-600 text-white rounded text-sm"
                                onClick={lambda { handle_delete(role); }}
                            >
                                Delete
                            </button>
                        }}
                    </div>
                }}
            </section>
        </div>;
}
