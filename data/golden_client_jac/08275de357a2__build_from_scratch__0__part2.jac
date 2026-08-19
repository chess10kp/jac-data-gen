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

obj Warrior(Character) {
    def postinit {
        self.strength = 20;  # Warriors hit harder
    }
}

obj Mage(Character) {
    def postinit {
        self.strength = 15;
    }

    def cast_spell(target: Character) {
        damage = self.strength * 2;  # Spells do double damage
        print(f"{self.name} casts fireball at {target.name} for {damage} damage!");
        target.take_damage(damage);
    }
}

with entry {
    warrior = Warrior(name="Conan");
    mage = Mage(name="Gandalf");

    warrior.attack(mage);
    mage.cast_spell(warrior);
}
