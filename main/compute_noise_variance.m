function noise_var = compute_noise_variance(cfg, EbN0_dB)
%COMPUTE_NOISE_VARIANCE Convert Eb/N0 to complex-sample noise variance.

    EbN0 = 10^(EbN0_dB / 10);
    pilot_factor = cfg.N_used / cfg.N_data;
    cp_factor = (cfg.N_subcarrier + cfg.N_GI) / cfg.N_subcarrier;
    noise_var = pilot_factor * cp_factor / (cfg.N_mod * cfg.R_code_eff * EbN0);
end
