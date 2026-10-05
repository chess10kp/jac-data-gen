node Crisis {
    has severity: any;
    has location: any;
    has status: any;
}

node Agent {
    has role: any;
    has active: any;
}

node Shelter {
    has capacity: any;
}

node Hospital {
    has occupancy: any;
}

node Resource {
    has availability: any;
}

edge responds_to {}
edge coordinates_with {}
edge deploys_to {}
