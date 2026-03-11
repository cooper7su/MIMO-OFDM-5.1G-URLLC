function [Frame_channel, H_freq, channel_info] = ApplyMIMOChannel(Frame_transmit, cfg)
%APPLYMIMOCHANNEL Apply AWGN, static TDL/Rician, or dynamic multipath channels.

    N_samples = size(Frame_transmit, 2);
    Frame_channel = complex(zeros(1, N_samples, cfg.N_Rx));
    H_freq = complex(zeros(cfg.N_subcarrier, cfg.N_Tx, cfg.N_Rx));

    switch upper(cfg.channel_model)
        case 'AWGN'
            tap_delays = 0;
            tap_powers = 1;
            channel_taps = ones(1, cfg.N_Tx, cfg.N_Rx);
            channel_info = struct('channel_model', 'AWGN', 'time_varying', false);

        case {'TDL-A', 'TDL-B', 'TDL-C', 'TDL-D'}
            if localUseDynamicTDL(cfg)
                profile = ResolveChannelProfile(cfg.channel_model, cfg.delay_spread_s);
                [Frame_channel, H_freq, channel_info] = ApplyDynamicMultipathChannel( ...
                    Frame_transmit, cfg, profile);
                return;
            end

            profile = ResolveChannelProfile(cfg.channel_model, cfg.delay_spread_s);
            tap_delays = round(profile.tap_delays_s * cfg.f_sample);
            tap_powers = profile.tap_powers;
            L = max(tap_delays) + 1;
            channel_taps = complex(zeros(L, cfg.N_Tx, cfg.N_Rx));
            for itx = 1:cfg.N_Tx
                for irx = 1:cfg.N_Rx
                    coeff = localGenerateTDLCoeff(tap_powers, profile);
                    for itap = 1:numel(tap_delays)
                        channel_taps(tap_delays(itap) + 1, itx, irx) = ...
                            channel_taps(tap_delays(itap) + 1, itx, irx) + coeff(itap);
                    end
                end
            end
            channel_info = struct('channel_model', upper(cfg.channel_model), ...
                'profile', profile, 'time_varying', false);

        case 'RICIAN'
            [Frame_channel, H_freq, channel_info] = ApplyRicianChannel(Frame_transmit, cfg);
            return;

        case {'DYNAMIC-RAYLEIGH', 'DYNAMIC-RICIAN'}
            profile = ResolveChannelProfile(cfg.channel_model, cfg.delay_spread_s);
            [Frame_channel, H_freq, channel_info] = ApplyDynamicMultipathChannel( ...
                Frame_transmit, cfg, profile);
            return;

        otherwise
            error('不支持的信道模型: %s', cfg.channel_model);
    end

    for irx = 1:cfg.N_Rx
        rx_signal = zeros(1, N_samples);
        for itx = 1:cfg.N_Tx
            h_td = channel_taps(:, itx, irx).';
            tx_signal = reshape(Frame_transmit(1, :, itx), 1, []);
            rx_signal = rx_signal + filter(h_td, 1, tx_signal);
            H_freq(:, itx, irx) = fftshift(fft(h_td(:), cfg.N_subcarrier));
        end
        Frame_channel(1, :, irx) = rx_signal;
    end

    channel_info.tap_delays = tap_delays(:);
    channel_info.tap_powers = tap_powers(:);
    channel_info.channel_taps = channel_taps;
end

function coeff = localGenerateTDLCoeff(tapPowers, profile)
    coeff = sqrt(tapPowers(:) / 2) .* ...
        (randn(numel(tapPowers), 1) + 1i * randn(numel(tapPowers), 1));

    if ~isempty(profile.los_tap_index)
        idx = profile.los_tap_index;
        K = profile.los_k_linear;
        losPhase = exp(1i * 2 * pi * rand(1));
        coeff(idx) = sqrt(tapPowers(idx) * K / (K + 1)) * losPhase + ...
            sqrt(tapPowers(idx) / (K + 1) / 2) * (randn(1) + 1i * randn(1));
    end
end

function tf = localUseDynamicTDL(cfg)
    tf = cfg.enable_dynamic_channel || cfg.use_fractional_delay || cfg.max_doppler_hz > 0;
end
