function roundtrip = run_noiseless_roundtrip(cfg)
%RUN_NOISELESS_ROUNDTRIP Validate the end-to-end chain without additive noise.

    rng(cfg.random_seed, 'twister');

    tx_frame = build_transmit_frame(cfg);
    [frame_channel, H_freq] = ApplyMIMOChannel(tx_frame.Frame_transmit, cfg);

    channel_state = struct();
    channel_state.Frame_channel = frame_channel;
    channel_state.Frame_rx = frame_channel;
    channel_state.H_freq = H_freq;
    channel_state.noise_var = 0;
    channel_state.channel_info = [];

    rx_frame = process_receive_frame(channel_state, tx_frame, cfg);

    roundtrip = struct();
    roundtrip.scenario_tag = cfg.scenario_tag;
    roundtrip.bitErrors = rx_frame.frameErrors;
    roundtrip.totalBits = rx_frame.frameBits;
    roundtrip.ber = rx_frame.frameErrors / rx_frame.frameBits;
    roundtrip.passed = (rx_frame.frameErrors == 0);
end
