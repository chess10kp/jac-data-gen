"""Main game logic for rock-paper-scissors choices."""
def gameLogic(compChoice: str, userChoice: str) -> str | None {
    if compChoice == 'r' {
        if userChoice == 'r' {
            return 't';
        } elif userChoice == 'p' {
            return 'w';
        } elif userChoice == 's' {
            return 'l';
        } else {
            print("Invalid Choice!");
        }
    } elif compChoice == 'p' {
        if userChoice == 'r' {
            return 'l';
        } elif userChoice == 'p' {
            return 't';
        } elif userChoice == 's' {
            return 'w';
        } else {
            print("Invalid Choice!");
        }
    } elif compChoice == 's' {
        if userChoice == 'r' {
            return 'w';
        } elif userChoice == 'p' {
            return 'l';
        } elif userChoice == 's' {
            return 't';
        } else {
            print("Invalid Choice!");
        }
    } else {
        print("Kuch toh gadbad hai bhaiya!");
    }
}