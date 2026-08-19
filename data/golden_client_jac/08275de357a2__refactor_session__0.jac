obj Character {
    has name: str;
    has health: int = 100;
    has strength: int = 10;
    def attack(target: Character);
    def take_damage(amount: int);
}

impl Character.attack(target: Character) {
    damage = self.strength;
    print(f"{self.name} attacks {target.name} for {damage} damage!");
    target.take_damage(damage);
}

impl Character.take_damage(amount: int) {
    self.health -= amount;
    print(f"{self.name} has {self.health} health remaining");
    if self.health <= 0 {
        print(f"{self.name} has been defeated!");
    }
}

obj Warrior(Character) {
    def postinit;
}

impl Warrior.postinit {
    self.strength = 20;
}

obj Mage(Character) {
    def postinit;
    def cast_spell(target: Character);
}

impl Mage.postinit {
    self.strength = 15;
}

impl Mage.cast_spell(target: Character) {
    damage = self.strength * 2;
    print(f"{self.name} casts fireball at {target.name} for {damage} damage!");
    target.take_damage(damage);
}

with entry {
    warrior = Warrior(name="Conan");
    mage = Mage(name="Gandalf");
    warrior.attack(mage);
    mage.cast_spell(warrior);
}
