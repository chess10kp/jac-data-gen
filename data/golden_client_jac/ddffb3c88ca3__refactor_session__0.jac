walker get_guestbook {
    has names: list[str] = [];
    can run with Root entry;
    can descend with Day entry;
    can gather with Visitor entry;
    can done with Root exit;
}

impl run { visit [-->[?:Day]]; }
impl descend { visit [here-->[?:Visitor]]; }
impl gather { self.names.append(here.name); }
impl done { self.names.sort(); }
