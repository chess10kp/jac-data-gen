impl SpotFinder.scan {
    visit [-->[?:Level]];
}

impl SpotFinder.survey {
    for s in here.free_spots(self.kind) {
        b = self.best;
        if b is None or here.number < self.best_level or (here.number == self.best_level and s.code < b.code) {
            self.best = s;
            self.best_level = here.number;
        }
    }
}

impl LocateCar.scan {
    visit [-->[?:Level]];
}

impl LocateCar.enter_level {
    visit [here ->:Contains:->];
}

impl LocateCar.check {
    cars = [here ->:Occupied:->[?:Car, plate == self.plate]];
    if cars {
        self.car = cars[0];
        self.spot = here;
        self.level = [here <-:Contains:<-][0];
        disengage;
    }
}
