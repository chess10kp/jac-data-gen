node Program {
    has label: str;
}
node Relation {
    has name: str;
    has external: bool = True;
}
node Column {
    has name: str;
}
node RelationMetadata {
    has name: str;
    has kind: str;
    has columns: list[str] = [];
    has not_null: list[str] = [];
    has unique_columns: list[str] = [];
}
node ViewDefinition {
    has name: str;
    has sql: str;
    has dependencies: list[str] = [];
}
node Knowledge {
    has kind: str;
    has relation: Relation;
    has column: Column | None = None;
    has position: int = -1;
}
edge Uses {}
edge Depends {}
edge HasColumn {}

obj DatabaseCatalog {
    has aliases: dict[str, str] = {};
    has kinds: dict[str, str] = {};
    has columns: dict[str, list[str]] = {};
    has not_null: dict[str, list[str]] = {};
    has unique_columns: dict[str, list[str]] = {};
    has view_sql: dict[str, str] = {};
    has view_deps: dict[str, list[str]] = {};
}
obj DatabaseHydration {
    has canonical: dict[str, str] = {};
    has kinds: dict[str, str] = {};
    has columns: dict[str, list[str]] = {};
    has not_null: dict[str, list[str]] = {};
    has unique_columns: dict[str, list[str]] = {};
    has view_sql: dict[str, str] = {};
    has view_deps: dict[str, list[str]] = {};
    has order: list[str] = [];
    has final_program: Program | None = None;
}
obj RebuildState {
    has final_program: Program;
    has hydration: DatabaseHydration;
    has copied: dict[str, Relation] = {};
}

def fetch_relation_metadata(
    catalog: DatabaseCatalog, names: list[str]
) -> list[RelationMetadata] {
    result: list[RelationMetadata] = [];
    for name in names {
        if name in catalog.kinds {
            cols: list[str] = [];
            nn: list[str] = [];
            uq: list[str] = [];
            if name in catalog.columns { cols = catalog.columns[name]; }
            if name in catalog.not_null { nn = catalog.not_null[name]; }
            if name in catalog.unique_columns { uq = catalog.unique_columns[name]; }
            result.append(RelationMetadata(
                name=name, kind=catalog.kinds[name],
                columns=cols, not_null=nn, unique_columns=uq
            ));
        }
    }
    return result;
}

def fetch_view_definition(
    catalog: DatabaseCatalog, relation: RelationMetadata
) -> ViewDefinition {
    sql: str = "";
    deps: list[str] = [];
    if relation.name in catalog.view_sql { sql = catalog.view_sql[relation.name]; }
    if relation.name in catalog.view_deps { deps = catalog.view_deps[relation.name]; }
    return ViewDefinition(name=relation.name, sql=sql, dependencies=deps);
}

walker HydrateWalker {
    has hydration: DatabaseHydration;
    has catalog: DatabaseCatalog;
    has claimed: dict[str, bool] = {};

    can discover_program with Program entry {
        print("discover program " + here.label);
        for relation in [here ->:Uses:->][?:Relation] {
            visit :0: [relation];
        }
    }

    can discover_relation with Relation entry {
        canonical_name: str = here.name;
        if here.name in self.catalog.aliases {
            canonical_name = self.catalog.aliases[here.name];
        }
        if canonical_name in self.claimed { skip; }
        self.claimed[canonical_name] = True;
        print("discover relation " + canonical_name);

        requested: list[str] = [];
        requested.append(canonical_name);
        metadata: list[RelationMetadata] =
            fetch_relation_metadata(self.catalog, requested);
        if len(metadata) == 0 { skip; }

        relation_metadata: RelationMetadata = metadata[0];
        self.hydration.canonical[here.name] = relation_metadata.name;
        self.hydration.kinds[relation_metadata.name] = relation_metadata.kind;
        self.hydration.columns[relation_metadata.name] = relation_metadata.columns;
        self.hydration.not_null[relation_metadata.name] =
            relation_metadata.not_null;
        self.hydration.unique_columns[relation_metadata.name] =
            relation_metadata.unique_columns;
        self.hydration.order.append(relation_metadata.name);

        if relation_metadata.kind == "view" {
            definition: ViewDefinition =
                fetch_view_definition(self.catalog, relation_metadata);
            self.hydration.view_sql[definition.name] = definition.sql;
            self.hydration.view_deps[definition.name] =
                definition.dependencies;
            for dependency_name in definition.dependencies {
                dependency = Relation(name=dependency_name, external=True);
                visit :0: [dependency];
            }
        }
    }
}

walker RebuildWalker {
    has state: RebuildState;
    has claimed: dict[str, bool] = {};

    can rebuild_program with Program entry {
        print("rebuild program " + here.label);
        for relation in [here ->:Uses:->][?:Relation] {
            visit :0: [relation];
        }
    }

    can rebuild_relation with Relation entry {
        canonical_name: str = here.name;
        if here.name in self.state.hydration.canonical {
            canonical_name = self.state.hydration.canonical[here.name];
        }
        if canonical_name in self.claimed { skip; }
        self.claimed[canonical_name] = True;

        copy = Relation(name=canonical_name, external=here.external);
        self.state.copied[canonical_name] = copy;
        self.state.final_program +>:Uses:+> copy;

        if canonical_name in self.state.hydration.columns {
            for column_name in self.state.hydration.columns[canonical_name] {
                column = Column(name=column_name);
                copy +>:HasColumn:+> column;
            }
        } else {
            for old_column in [here ->:HasColumn:->][?:Column] {
                column = Column(name=old_column.name);
                copy +>:HasColumn:+> column;
            }
        }

        if canonical_name in self.state.hydration.view_deps {
            for dependency_name in
                self.state.hydration.view_deps[canonical_name] {
                child: Relation;
                if dependency_name in self.state.copied {
                    child = self.state.copied[dependency_name];
                } else {
                    child = Relation(name=dependency_name, external=True);
                }
                copy +>:Depends:+> child;
                visit :0: [child];
            }
        }
    }
}

walker BindWalker {
    has hydration: DatabaseHydration;
    has facts: list[Knowledge] = [];
    has claimed: dict[str, bool] = {};

    can bind_program with Program entry {
        print("bind program " + here.label);
        for relation in [here ->:Uses:->][?:Relation] {
            visit :0: [relation];
        }
    }

    can bind_relation with Relation entry {
        canonical_name: str = here.name;
        if here.name in self.hydration.canonical {
            canonical_name = self.hydration.canonical[here.name];
        }
        if canonical_name in self.claimed { skip; }
        self.claimed[canonical_name] = True;
        print("bind relation " + canonical_name);

        if canonical_name in self.hydration.kinds {
            self.facts.append(Knowledge(
                kind="relation", relation=here
            ));
            if canonical_name in self.hydration.unique_columns {
                unique_columns = self.hydration.unique_columns[canonical_name];
                if len(unique_columns) > 0 {
                    self.facts.append(Knowledge(
                        kind="unique_set", relation=here
                    ));
                }
            }
            position: int = 0;
            for column in [here ->:HasColumn:->][?:Column] {
                if canonical_name in self.hydration.not_null {
                    if column.name in self.hydration.not_null[canonical_name] {
                        self.facts.append(Knowledge(
                            kind="non_null_column",
                            relation=here, column=column
                        ));
                    }
                }
                if canonical_name in self.hydration.unique_columns {
                    if column.name in
                        self.hydration.unique_columns[canonical_name] {
                        self.facts.append(Knowledge(
                            kind="unique_set_column",
                            relation=here, column=column,
                            position=position
                        ));
                        position += 1;
                    }
                }
            }
        }

        for child in [here ->:Depends:->][?:Relation] {
            visit :0: [child];
        }
    }
}

def hydrate(
    program: Program, catalog: DatabaseCatalog
) -> DatabaseHydration {
    hydration = DatabaseHydration();
    program spawn HydrateWalker(
        hydration=hydration, catalog=catalog, claimed={}
    );
    final_program = Program(label=program.label);
    rebuild_state = RebuildState(
        final_program=final_program, hydration=hydration
    );
    program spawn RebuildWalker(state=rebuild_state, claimed={});
    hydration.final_program = final_program;
    return hydration;
}

def bind(
    program: Program, hydration: DatabaseHydration
) -> tuple[Knowledge, ...] {
    binder = program spawn BindWalker(hydration=hydration, claimed={});
    return tuple(binder.facts);
}

with entry {
    demo_program = Program(label="demo");
    root ++> demo_program;
    demo_relation = Relation(name="demo.table", external=True);
    demo_program +>:Uses:+> demo_relation;
    demo_catalog = DatabaseCatalog(
        kinds={"demo.table": "table"},
        columns={"demo.table": ["id"]}
    );
    demo_hydration = DatabaseHydration();
    root spawn HydrateWalker(
        hydration=demo_hydration,
        catalog=demo_catalog,
        claimed={}
    );
}
