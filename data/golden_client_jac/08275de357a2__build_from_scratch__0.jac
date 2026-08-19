obj Character {
    has name: str;
    has health: int = 100;
    has strength: int = 10;

    def attack(target: Character) {
        damage = self.strength;
        print(f"{self.name} attacks {target.name} for {damage} damage!");
        target.take_damage(damage);
    }

    def take_damage(amount: int) {
        self.health -= amount;
        print(f"{self.name} has {self.health} health remaining");
        if self.health <= 0 {
            print(f"{self.name} has been defeated!");
        }
    }
}
