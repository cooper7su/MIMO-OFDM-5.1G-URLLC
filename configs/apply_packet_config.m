function cfg = apply_packet_config(cfg)
%APPLY_PACKET_CONFIG Normalize packet-length settings for finite-blocklength runs.

    if ~isfield(cfg, 'packet_length_mode') || isempty(cfg.packet_length_mode)
        cfg.packet_length_mode = 'long';
    end
    cfg.packet_length_mode = char(lower(string(cfg.packet_length_mode)));

    if ~isfield(cfg, 'packet_profiles') || isempty(cfg.packet_profiles)
        cfg.packet_profiles = local_default_packet_profiles();
    end

    if ~isfield(cfg, 'bler_target_thresholds') || isempty(cfg.bler_target_thresholds)
        cfg.bler_target_thresholds = [1e-3, 1e-4];
    end
    cfg.bler_target_thresholds = unique(cfg.bler_target_thresholds(:).', 'stable');

    activeProfile = local_select_profile(cfg.packet_profiles, cfg.packet_length_mode);
    if ~isempty(cfg.N_symbols_per_packet)
        cfg.N_symbol = cfg.N_symbols_per_packet;
    elseif isfield(activeProfile, 'N_symbol') && ~isempty(activeProfile.N_symbol)
        cfg.N_symbol = activeProfile.N_symbol;
    end

    if isempty(cfg.N_bits_per_packet) && isfield(activeProfile, 'N_bits_per_packet')
        cfg.N_bits_per_packet = activeProfile.N_bits_per_packet;
    end

    cfg.packet_symbol_count = cfg.N_symbol;
    cfg.packet_length_label = upper(char(cfg.packet_length_mode));
    cfg.enable_finite_blocklength = cfg.short_packet_mode || ...
        ~strcmpi(cfg.packet_length_mode, "long") || ...
        ~isempty(cfg.N_symbols_per_packet) || ...
        ~isempty(cfg.N_bits_per_packet);
end

function profile = local_select_profile(packetProfiles, packetLengthMode)
    profile = struct();
    fieldNames = fieldnames(packetProfiles);
    for ifield = 1:numel(fieldNames)
        if strcmpi(fieldNames{ifield}, packetLengthMode)
            profile = packetProfiles.(fieldNames{ifield});
            return;
        end
    end
end

function packetProfiles = local_default_packet_profiles()
    packetProfiles = struct();
    packetProfiles.short = struct('N_symbol', 4, 'N_bits_per_packet', []);
    packetProfiles.medium = struct('N_symbol', 8, 'N_bits_per_packet', []);
    packetProfiles.long = struct('N_symbol', 12, 'N_bits_per_packet', []);
end
