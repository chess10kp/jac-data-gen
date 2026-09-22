"""
	Node numbering scheme is as follows:
	[c1-c309] [c321-c478] old compute nodes (Sandy Bridge)
	[c579-c628],[c639-c985] new compute nodes (Haswell) -- 50 + 346

	Special nodes:
	c309-c320 old big memory nodes (Sandy Bridge)
	c629-c638 new big memory nodes (Haswell) -- 10
	c577,c578 old huge memory nodes (HP Proliant DL560)
	c986-c989 new huge memory nodes (Dell R930)

	TOTAL Haswell 406
	"""
def node_type(`node: Any) -> object {
    if (`node.strip() in [('c' + str(x)) for x in range(1, 310)]) {
        return 'SandyBridge';
    }
    if (`node.strip() in [('c' + str(x)) for x in range(321, 479)]) {
        return 'SandyBridge';
    }
    if (`node.strip() in [('c' + str(x)) for x in range(579, 629)]) {
        return 'Haswell';
    }
    if (`node.strip() in [('c' + str(x)) for x in range(639, 986)]) {
        return 'Haswell';
    }
    if (`node.strip() in [('c' + str(x)) for x in range(309, 321)]) {
        return 'SandyBridgeBig';
    }
    if (`node.strip() in [('c' + str(x)) for x in range(629, 639)]) {
        return 'HaswellBig';
    }
    if (`node.strip() in [('c' + str(x)) for x in range(577, 579)]) {
        return 'OldHuge';
    }
    if (`node.strip() in [('c' + str(x)) for x in range(986, 990)]) {
        return 'NewHuge';
    }
}