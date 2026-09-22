def generate_moku_manager_params(
    drop_mode: bool,
    moku_size: int,
    board_size: tuple[int, int],
    gpu_id: int,
    num_res_layers: int,
    num_channels: int,
    ckpt_path: str | None = None,
    replace_unloaded_resnet_by_naivenet: bool = True
) -> tuple[
    str,
    list[str],
    dict[str, bool | int | str | tuple[int, int] | None],
    list[str],
    dict[str, bool | tuple[int, int]]
] {
    if gpu_id < 0 {
        tf_device = '/cpu:0';
    } else {
        tf_device = '/gpu:' + str(gpu_id);
    }
    game_config_string = 'moku_%d_%dx%d' % (moku_size, board_size[0], board_size[1]);
    if drop_mode {
        game_config_string += '_drop';
    }
    game_manager_module = ['moku_manager', 'MokuManager'];
    game_manager_kwargs = {
        'drop_mode': drop_mode,
        'moku_size': moku_size,
        'board_size': board_size,
        'tf_device': tf_device,
        'num_res_layers': num_res_layers,
        'num_channels': num_channels,
        'ckpt_path': ckpt_path,
        'replace_unloaded_resnet_by_naivenet': replace_unloaded_resnet_by_naivenet
    };
    game_manager_io_module = ['moku_manager_io', 'MokuManagerIO'];
    game_manager_io_kwargs = {'drop_mode': drop_mode, 'board_size': board_size};
    return (
        game_config_string,
        game_manager_module,
        game_manager_kwargs,
        game_manager_io_module,
        game_manager_io_kwargs
    );
}