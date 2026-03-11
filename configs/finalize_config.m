function cfg = finalize_config(cfg)
%FINALIZE_CONFIG Derive all secondary parameters from the base config.

    cfg = apply_packet_config(cfg);
    cfg.N_sym = cfg.N_subcarrier + cfg.N_GI;
    if isempty(cfg.max_doppler_hz)
        c_light = 299792458;
        cfg.max_doppler_hz = abs(cfg.velocity_mps) * cfg.f_carrier / c_light;
    end

    cfg.index_data_base = IndexDataGenerator(cfg.index_used_base, cfg.index_pilot_base);
    shift = cfg.N_subcarrier / 2 + 1;
    cfg.index_used = cfg.index_used_base + shift;
    cfg.index_pilot = cfg.index_pilot_base + shift;
    cfg.index_data = cfg.index_data_base + shift;

    cfg.N_used = numel(cfg.index_used);
    cfg.N_pilot = numel(cfg.index_pilot);
    cfg.N_data = numel(cfg.index_data);
    cfg.frame_capacity_bits = cfg.N_mod * (cfg.N_data / cfg.N_user) * cfg.N_symbol;
    cfg.mod_name = local_modulation_name(cfg.N_mod);

    cfg = finalize_coding_config(cfg);
    cfg.eta_eff = cfg.N_mod * cfg.R_code_eff * (cfg.N_data / cfg.N_subcarrier) * ...
        (cfg.N_subcarrier / (cfg.N_subcarrier + cfg.N_GI));
    cfg.frame_duration_s = cfg.N_symbol * cfg.N_sym / cfg.f_sample;
    cfg.symbol_duration_s = cfg.N_sym / cfg.f_sample;
    cfg.pilot_overhead_ratio = cfg.N_pilot / max(cfg.N_used, 1);
    cfg.pilot_overhead_time_s = cfg.frame_duration_s * cfg.pilot_overhead_ratio;
    cfg.latency_proxy_s = cfg.frame_duration_s + cfg.pilot_overhead_time_s;
    cfg.payload_bits_per_frame = sum(cfg.info_bits_per_user);
    cfg.payload_bits_per_packet = cfg.payload_info_bits;
    cfg.packet_length_bits = cfg.payload_bits_per_packet;
    cfg.packet_length_symbols = cfg.N_symbol;
    cfg.nominal_payload_throughput_bps = cfg.payload_bits_per_frame / cfg.frame_duration_s;
    cfg.nominal_throughput_bps = cfg.payload_bits_per_frame / cfg.latency_proxy_s;
    cfg.coding_overhead_ratio = max(cfg.valid_coded_bits / max(cfg.payload_bits_per_frame, 1) - 1, 0);
    cfg.stbc = GetSTBCConfig(cfg.N_Tx);
    cfg.csi_modes = get_csi_mode_list(cfg);
    cfg.primary_csi_mode = cfg.csi_modes{1};

    if isfield(cfg, 'scenario_name') && ~isempty(cfg.scenario_name)
        cfg.scenario_tag = cfg.scenario_name;
    else
        channelLabel = upper(cfg.channel_model);
        if localIsDynamicTdl(cfg)
            channelLabel = [channelLabel '-DYN'];
        end
        cfg.scenario_tag = sprintf('%dx%d_%s_%s_%s', ...
            cfg.N_Tx, cfg.N_Rx, channelLabel, upper(cfg.Coded_method), cfg.mod_name);
        if ~strcmpi(cfg.packet_length_mode, 'long')
            cfg.scenario_tag = sprintf('%s_%s', cfg.scenario_tag, cfg.packet_length_label);
        end
    end
end

function mod_name = local_modulation_name(N_mod)
    switch N_mod
        case 1
            mod_name = 'BPSK';
        case 2
            mod_name = 'QPSK';
        otherwise
            mod_name = sprintf('%d-bit', N_mod);
    end
end

function tf = localIsDynamicTdl(cfg)
    tf = startsWith(upper(cfg.channel_model), 'TDL-', 'IgnoreCase', true) && ...
        (cfg.enable_dynamic_channel || cfg.use_fractional_delay || cfg.max_doppler_hz > 0);
end
