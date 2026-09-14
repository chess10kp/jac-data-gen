"""Idiomatic OSP training record for felipegbpr/prazordoc#4."""

node Organization {
    has org_id: str;
    has timezone: str = "UTC";
    has retention_policy: str = "standard";
}

node Category {
    has category_id: str;
    has name: str;
    has active: bool = True;
}

node DocumentType {
    has type_id: str;
    has name: str;
    has expiration_days: int = 0;
    has active: bool = True;
}

node Document {
    has document_id: str;
    has title: str;
    has archived: bool = False;
}

edge Contains {}
edge Tagged {}
edge Typed {}

obj TaxonomyStore {
    has organization: Organization;
}

walker CatalogWalker {
    has claimed: dict[str, bool] = {};
    has categories: list[Category] = [];
    has document_types: list[DocumentType] = [];
    has documents: list[Document] = [];

    can collect_org with Organization entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("catalog organization");
        for kid in [here ->:Contains:->][?:Category] { visit :0: [kid]; }
        for kid in [here ->:Contains:->][?:DocumentType] { visit :0: [kid]; }
        for kid in [here ->:Contains:->][?:Document] { visit :0: [kid]; }
    }

    can collect_category with Category entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.categories.append(here);
        print("catalog category");
        for kid in [here ->:Tagged:->][?:Document] { visit :0: [kid]; }
    }

    can collect_type with DocumentType entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.document_types.append(here);
        print("catalog document type");
        for kid in [here ->:Typed:->][?:Document] { visit :0: [kid]; }
    }

    can collect_document with Document entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.documents.append(here);
        print("catalog document");
    }
}

walker CategoryUsageWalker {
    has claimed: dict[str, bool] = {};
    has in_use: bool = False;

    can inspect_category with Category entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("inspect category usage");
        for doc in [here ->:Tagged:->][?:Document] { visit :0: [doc]; }
    }

    can inspect_document with Document entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.in_use = True;
        print("category is referenced");
    }
}

def read_settings(store: TaxonomyStore) -> dict[str, str] {
    settings: dict[str, str] = {};
    settings["timezone"] = store.organization.timezone;
    settings["retention_policy"] = store.organization.retention_policy;
    return settings;
}

def update_settings(store: TaxonomyStore, timezone: str, retention_policy: str) -> bool {
    if timezone == "" { return False; }
    if retention_policy == "" { return False; }
    store.organization.timezone = timezone;
    store.organization.retention_policy = retention_policy;
    return True;
}

def list_categories(store: TaxonomyStore) -> list[Category] {
    w = store.organization spawn CatalogWalker(claimed={});
    return w.categories;
}

def list_active_categories(store: TaxonomyStore) -> list[Category] {
    result: list[Category] = [];
    for category in list_categories(store) {
        if category.active { result.append(category); }
    }
    return result;
}

def find_category(store: TaxonomyStore, category_id: str) -> Category | None {
    for category in list_categories(store) {
        if category.category_id == category_id { return category; }
    }
    return None;
}

def create_category(store: TaxonomyStore, category_id: str, name: str) -> Category | None {
    if category_id == "" { return None; }
    if name == "" { return None; }
    for category in list_categories(store) {
        if category.category_id == category_id { return None; }
        if category.name == name { return None; }
    }
    category = Category(category_id=category_id, name=name);
    store.organization +>:Contains:+> category;
    return category;
}

def update_category(store: TaxonomyStore, category_id: str, name: str) -> bool {
    if name == "" { return False; }
    category = find_category(store, category_id);
    if category == None { return False; }
    for other in list_categories(store) {
        if other.category_id != category_id {
            if other.name == name { return False; }
        }
    }
    category.name = name;
    return True;
}

def archive_category(store: TaxonomyStore, category_id: str) -> bool {
    category = find_category(store, category_id);
    if category == None { return False; }
    usage = category spawn CategoryUsageWalker(claimed={});
    if usage.in_use {
        category.active = False;
        return True;
    }
    category.active = False;
    return True;
}

def list_document_types(store: TaxonomyStore) -> list[DocumentType] {
    w = store.organization spawn CatalogWalker(claimed={});
    return w.document_types;
}

def list_active_document_types(store: TaxonomyStore) -> list[DocumentType] {
    result: list[DocumentType] = [];
    for doc_type in list_document_types(store) {
        if doc_type.active { result.append(doc_type); }
    }
    return result;
}

def find_document_type(store: TaxonomyStore, type_id: str) -> DocumentType | None {
    for doc_type in list_document_types(store) {
        if doc_type.type_id == type_id { return doc_type; }
    }
    return None;
}

def create_document_type(store: TaxonomyStore, type_id: str, name: str, expiration_days: int) -> DocumentType | None {
    if type_id == "" { return None; }
    if name == "" { return None; }
    if expiration_days < 0 { return None; }
    for doc_type in list_document_types(store) {
        if doc_type.type_id == type_id { return None; }
        if doc_type.name == name { return None; }
    }
    doc_type = DocumentType(type_id=type_id, name=name, expiration_days=expiration_days);
    store.organization +>:Contains:+> doc_type;
    return doc_type;
}

def update_document_type(store: TaxonomyStore, type_id: str, name: str, expiration_days: int) -> bool {
    if name == "" { return False; }
    if expiration_days < 0 { return False; }
    doc_type = find_document_type(store, type_id);
    if doc_type == None { return False; }
    for other in list_document_types(store) {
        if other.type_id != type_id {
            if other.name == name { return False; }
        }
    }
    doc_type.name = name;
    doc_type.expiration_days = expiration_days;
    return True;
}

def archive_document_type(store: TaxonomyStore, type_id: str) -> bool {
    doc_type = find_document_type(store, type_id);
    if doc_type == None { return False; }
    doc_type.active = False;
    return True;
}

def register_document(store: TaxonomyStore, document_id: str, title: str, category_id: str, type_id: str) -> Document | None {
    if document_id == "" { return None; }
    if title == "" { return None; }
    category = find_category(store, category_id);
    if category == None { return None; }
    doc_type = find_document_type(store, type_id);
    if doc_type == None { return None; }
    if category.active == False { return None; }
    if doc_type.active == False { return None; }
    doc = Document(document_id=document_id, title=title);
    store.organization +>:Contains:+> doc;
    category +>:Tagged:+> doc;
    doc_type +>:Typed:+> doc;
    return doc;
}

def list_documents(store: TaxonomyStore) -> list[Document] {
    w = store.organization spawn CatalogWalker(claimed={});
    return w.documents;
}

def archive_document(store: TaxonomyStore, document_id: str) -> bool {
    for doc in list_documents(store) {
        if doc.document_id == document_id {
            doc.archived = True;
            return True;
        }
    }
    return False;
}
