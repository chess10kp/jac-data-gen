"""Theme park operations capstone.

Combines several OSP tools in one runnable park: the rider walker gates
roller coasters by height with ``disengage``, water rides pay out fun
points, food stalls and gift shops share one union-triggered purchase
ability (`FoodStall | GiftShop`) whose stops are told apart with typed
context blocks, and shared shop fields come from a common base node.
"""

node Attraction {
    has name: str;
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

node FoodStall(ShopStop) {}

node GiftShop(ShopStop) {}

walker Rider {
    has rider_name: str;
    has height_cm: int;
    has fun_points: int = 0;
    has purchases: int = 0;
    has spend: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can explore with Attraction entry {
        if isinstance(here, RollerCoaster) {
            if self.height_cm < here.min_height_cm {
                print(f"{self.rider_name} is TOO SHORT for {here.name} "
                      f"(needs {here.min_height_cm} cm)");
                disengage;
            }
            self.fun_points += here.thrill * 10;
            print(f"{self.rider_name} rides {here.name} (+{here.thrill * 10} fun)");
        }
        if isinstance(here, WaterRide) {
            self.fun_points += here.splash_level * 5;
            print(f"{self.rider_name} gets soaked on {here.name} "
                  f"(+{here.splash_level * 5} fun)");
        }
        visit [-->];
    }

    # Union trigger: one ability serves both kinds of shopping stop,
    # with a typed context block adding each stop's own flavour.
    can shop with FoodStall | GiftShop entry {
        ->FoodStall{
            print(f"{self.rider_name} grabs a fresh {here.item_name}. Tasty!");
        }
        ->GiftShop{
            print(f"{self.rider_name} picks up a {here.item_name}. Shiny!");
        }
        self.purchases += 1;
        self.spend += here.price;
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
