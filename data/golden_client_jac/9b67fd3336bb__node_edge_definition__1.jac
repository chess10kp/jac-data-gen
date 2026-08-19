node Person {}
edge Friend { has since: int = 2020; }

walker Visitor {
    can filter with Person entry {
        visit [-->][?:Person];          # Visit Person nodes only
        visit [->:Friend:->];           # Visit via Friend edges only
        visit [->:Friend:since>2020:->]; # Via Friend edges with condition
    }
}
