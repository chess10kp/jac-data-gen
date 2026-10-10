import from survey { LogSighting, SiteList, Scarce }

with entry {
    root spawn LogSighting(site="Pond", species="Teal", count=5, day=12);
    l = root spawn SiteList(site="Pond");
    print("POND=" + ",".join(l.reports[0]));
    s = root spawn Scarce(max_sites=1);
    print("SCARCE=" + ",".join(s.reports[0]));
}
