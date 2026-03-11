function channel_state = run_frame_channel(frame_transmit, cfg, EbN0_dB)
%RUN_FRAME_CHANNEL Apply the configured channel and additive noise.

    [frame_channel, H_freq, channel_info] = ApplyMIMOChannel(frame_transmit, cfg);
    noise_var = compute_noise_variance(cfg, EbN0_dB);
    frame_rx = frame_channel + NoiseGenerator(noise_var, size(frame_channel, 2), cfg.N_Rx);

    channel_state = struct();
    channel_state.Frame_channel = frame_channel;
    channel_state.Frame_rx = frame_rx;
    channel_state.H_freq = H_freq;
    channel_state.noise_var = noise_var;
    channel_state.channel_info = channel_info;
end
