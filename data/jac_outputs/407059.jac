"""retourne un dictionnaire partiel de mot de taille n correctement parenthese"""
def dic_partiel(n: int) -> list[str] {
    if n <= 0 {
        return [""];
    } elif n == 1 {
        return ["()"];
    }
    sub_list = dic_partiel(n - 1);
    new_list = [];
    for word in sub_list {
        new_list.append(word + "()");
        new_list.append("(" + word + ")");
    }
    return new_list;
}