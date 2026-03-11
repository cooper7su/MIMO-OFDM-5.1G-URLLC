function [Frame_channel, H_freq, channel_info] = ApplyDynamicMultipathChannel(Frame_transmit, cfg, profile)
%APPLYDYNAMICMULTIPATHCHANNEL Apply a symbol-varying frequency-selective channel.

    if nargin < 3 || isempty(profile)
        profile = ResolveChannelProfile(cfg.channel_model, cfg.delay_spread_s);
    end

    N_samples_per_symbol = cfg.N_sym;
    fractionalSpan = max(round(cfg.fractional_delay_span), 4);
    tapDelaysSamples = profile.tap_delays_s(:) * cfg.f_sample;
    numTaps = numel(tapDelaysSamples);
    K_linear = localResolveKFactor(cfg, profile);

    Frame_channel = complex(zeros(1, N_samples_per_symbol * cfg.N_symbol, cfg.N_Rx));
    H_freq = complex(zeros(cfg.N_subcarrier, cfg.N_symbol, cfg.N_Tx, cfg.N_Rx));
    tap_coeffs = complex(zeros(numTaps, cfg.N_symbol, cfg.N_Tx, cfg.N_Rx));
    max_h_len = max(floor(tapDelaysSamples)) + fractionalSpan + 2;
    h_td_store = complex(zeros(max_h_len, cfg.N_symbol, cfg.N_Tx, cfg.N_Rx));

    rho = localTemporalCorrelation(cfg);
    txSymbols = complex(zeros(N_samples_per_symbol, cfg.N_symbol, cfg.N_Tx));
    for itx = 1:cfg.N_Tx
        txSymbols(:, :, itx) = reshape(Frame_transmit(1, :, itx), N_samples_per_symbol, cfg.N_symbol);
    end

    if ~isempty(profile.los_tap_index)
        losDopplerScale = max(cfg.max_doppler_hz, 0);
        losAngles = 2 * pi * rand(cfg.N_Tx, cfg.N_Rx);
        losPhases = 2 * pi * rand(cfg.N_Tx, cfg.N_Rx);
    else
        losDopplerScale = 0;
        losAngles = [];
        losPhases = [];
    end

    for itx = 1:cfg.N_Tx
        for irx = 1:cfg.N_Rx
            scatterState = sqrt(profile.tap_powers(:) / 2) .* ...
                (randn(numTaps, 1) + 1i * randn(numTaps, 1));

            for isym = 1:cfg.N_symbol
                if isym > 1
                    innovation = sqrt(profile.tap_powers(:) / 2) .* ...
                        (randn(numTaps, 1) + 1i * randn(numTaps, 1));
                    scatterState = rho * scatterState + sqrt(max(1 - abs(rho)^2, 0)) * innovation;
                end

                tap_coeffs(:, isym, itx, irx) = scatterState;
                h_td = localBuildImpulseResponse( ...
                    tapDelaysSamples, scatterState, profile, K_linear, ...
                    cfg, itx, irx, isym, losDopplerScale, losAngles, losPhases, fractionalSpan);
                h_td_store(1:numel(h_td), isym, itx, irx) = h_td;
                H_freq(:, isym, itx, irx) = fftshift(fft(h_td(:), cfg.N_subcarrier));
            end
        end
    end

    for irx = 1:cfg.N_Rx
        rxSymbols = complex(zeros(N_samples_per_symbol, cfg.N_symbol));
        for itx = 1:cfg.N_Tx
            for isym = 1:cfg.N_symbol
                h_td = squeeze(h_td_store(:, isym, itx, irx));
                h_td = h_td(any(abs(h_td) > 0, 2));
                if isempty(h_td)
                    h_td = 1;
                end
                convOutput = conv(txSymbols(:, isym, itx), h_td(:));
                rxSymbols(:, isym) = rxSymbols(:, isym) + convOutput(1:N_samples_per_symbol);
            end
        end
        Frame_channel(1, :, irx) = reshape(rxSymbols, 1, []);
    end

    channel_info = struct();
    channel_info.channel_model = upper(cfg.channel_model);
    channel_info.time_varying = true;
    channel_info.profile = profile;
    channel_info.tap_delays_samples = tapDelaysSamples;
    channel_info.tap_powers = profile.tap_powers(:);
    channel_info.tap_coeffs = tap_coeffs;
    channel_info.temporal_correlation = rho;
    channel_info.max_doppler_hz = cfg.max_doppler_hz;
end

function rho = localTemporalCorrelation(cfg)
    if cfg.max_doppler_hz <= 0
        rho = min(max(cfg.dynamic_fading_correlation, 0), 0.9999);
        return;
    end

    rho = besselj(0, 2 * pi * cfg.max_doppler_hz * cfg.symbol_duration_s);
    if ~isfinite(rho)
        rho = cfg.dynamic_fading_correlation;
    end
    rho = min(max(real(rho), 0), 0.9999);
end

function K_linear = localResolveKFactor(cfg, profile)
    K_linear = [];
    if ~isempty(profile.los_k_linear)
        K_linear = profile.los_k_linear;
    elseif contains(upper(profile.name), 'RICIAN')
        K_linear = cfg.K_factor;
    end
end

function h_td = localBuildImpulseResponse( ...
        tapDelaysSamples, scatterState, profile, K_linear, cfg, itx, irx, isym, ...
        losDopplerScale, losAngles, losPhases, fractionalSpan)
    h_len = max(floor(tapDelaysSamples)) + fractionalSpan + 2;
    h_td = complex(zeros(h_len, 1));
    losIndex = profile.los_tap_index;

    for itap = 1:numel(tapDelaysSamples)
        coeff = scatterState(itap);
        if ~isempty(losIndex) && itap == losIndex
            if isempty(K_linear)
                K_linear = cfg.K_factor;
            end
            losPhase = losPhases(itx, irx) + ...
                2 * pi * losDopplerScale * cos(losAngles(itx, irx)) * ...
                (isym - 1) * cfg.symbol_duration_s;
            losCoeff = sqrt(profile.tap_powers(itap) * K_linear / (K_linear + 1)) * exp(1i * losPhase);
            coeff = losCoeff + scatterState(itap) / sqrt(K_linear + 1);
        end

        basis = localFractionalDelayBasis(tapDelaysSamples(itap), h_len, fractionalSpan, cfg.use_fractional_delay);
        h_td = h_td + coeff * basis;
    end
end

function basis = localFractionalDelayBasis(delaySamples, hLen, fractionalSpan, useFractionalDelay)
    basis = complex(zeros(hLen, 1));
    if ~useFractionalDelay
        tapIndex = round(delaySamples) + 1;
        tapIndex = min(max(tapIndex, 1), hLen);
        basis(tapIndex) = 1;
        return;
    end

    baseIndex = floor(delaySamples);
    fracDelay = delaySamples - baseIndex;
    support = (-fractionalSpan:fractionalSpan).';
    tapIndex = baseIndex + support + 1;
    validMask = tapIndex >= 1 & tapIndex <= hLen;
    window = 0.5 * (1 + cos(pi * support / max(fractionalSpan, 1)));
    sincArg = support - fracDelay;
    coeff = sinc(sincArg) .* window;
    coeff = coeff / max(sum(coeff(validMask)), eps);
    basis(tapIndex(validMask)) = coeff(validMask);
end
