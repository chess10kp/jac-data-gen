"""Theme park operations capstone.

Combines several OSP tools in one runnable park: the rider walker gates
roller coasters by height with ``disengage``, water rides pay out fun
points, food stalls and gift shops share one union-triggered purchase
ability (`FoodStall | GiftShop`) whose stops are told apart with typed
context blocks, and shared shop fields come from a common base node.
"""

node Attraction {
    has name: str;

    can explore with Rider entry {
        if isinstance(self, RollerCoaster) {
            if visitor.height_cm < self.min_height_cm {
                print(f"{visitor.rider_name} is TOO SHORT for {self.name} "
                      f"(needs {self.min_height_cm} cm)");
                disengage;
            }
            visitor.fun_points += self.thrill * 10;
            print(f"{visitor.rider_name} rides {self.name} (+{self.thrill * 10} fun)");
        }
        if isinstance(self, WaterRide) {
            visitor.fun_points += self.splash_level * 5;
            print(f"{visitor.rider_name} gets soaked on {self.name} "
                  f"(+{self.splash_level * 5} fun)");
        }
        visit [-->];
    }
}

node RollerCoaster(Attraction) {
    has min_height_cm: int;
    has thrill: int;
}

node WaterRide(Attraction) {
    has splash_level: int;
}

node ShopStop {
    has item_name: str;
    has price: int = 6;
}

node FoodStall(ShopStop) {
    can shop with Rider entry {
        print(f"{visitor.rider_name} grabs a fresh {self.item_name}. Tasty!");
        visitor.purchases += 1;
        visitor.spend += self.price;
    }
}

node GiftShop(ShopStop) {
    can shop with Rider entry {
        print(f"{visitor.rider_name} picks up a {self.item_name}. Shiny!");
        visitor.purchases += 1;
        visitor.spend += self.price;
    }
}

walker Rider {
    has rider_name: str;
    has height_cm: int;
    has fun_points: int = 0;
    has purchases: int = 0;
    has spend: int = 0;

    can start with Root entry {
        visit [-->];
    }
}

with entry {
    midway = Attraction(name="Midway");
    root ++> midway;

    viper = RollerCoaster(name="Viper", min_height_cm=130, thrill=9);
    logflume = WaterRide(name="Log Flume", splash_level=7);
    midway ++> viper ++> logflume;

    churro_stand = FoodStall(item_name="churro", price=6);
    coin_shop = GiftShop(item_name="plastic tiara", price=12);
    midway ++> churro_stand;
    midway ++> coin_shop;

    tall_guest = Rider(rider_name="Ivy", height_cm=155);
    root spawn tall_guest;
    print(f"Ivy: {tall_guest.fun_points} fun, spent ${tall_guest.spend}");

    small_guest = Rider(rider_name="Bo", height_cm=118);
    root spawn small_guest;
    print(f"Bo: {small_guest.fun_points} fun, spent ${small_guest.spend}");
}