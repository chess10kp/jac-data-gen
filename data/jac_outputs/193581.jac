"""
	given a .newick subtree as a string, return a list of the tips

	args
		string: should be a .newick string eg "((A,B),((C,D),E))"
	returns
		overall_tiplist: a list that looks like ["A", "B", "C", "D", "E"]
		str_to_tips: a dict of all subclades to their tiplists. {"((A,B),((C,D),E))":["A", "B", "C", "D", "E"],
								(A,B):[A,B] ...etc}
	"""
def String_to_Tips(string: str) -> tuple[dict[str, list[str]], list[str]] {
    depth = 0;
    depth_to_index = {};
    index = 0;
    str_to_tips = {};
    list_of_strings = [];
    overall_tiplist = [];
    for item in string {
        if item == "(" {
            depth += 1;
            depth_to_index[depth] = index;
        }
        if item == ")" {
            list_of_strings.append(string[depth_to_index[depth]:(index + 1)]);
            depth -= 1;
        }
        index += 1;
    }
    for item in list_of_strings {
        tiplist = [];
        item2 = item.replace("(", "");
        item2 = item2.replace(")", "");
        items2 = item2.split(",");
        for tip in items2 {
            tipsplits = tip.split(":");
            tip = tipsplits[0];
            tiplist.append(tip);
            if tip not in overall_tiplist {
                overall_tiplist.append(tip);
            }
        }
        str_to_tips[item] = tiplist;
    }
    return (str_to_tips, overall_tiplist);
}