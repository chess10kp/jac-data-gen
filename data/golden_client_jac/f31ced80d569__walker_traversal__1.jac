walker:pub GetMyData {
    can get with Root entry {
        # 'here' is the user-specific root node
        my_data = [-->][?:MyData];
        report my_data;
    }
}
