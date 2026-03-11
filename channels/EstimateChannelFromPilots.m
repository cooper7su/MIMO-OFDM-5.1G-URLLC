function [H_est, estimationInfo] = EstimateChannelFromPilots( ...
        Frame_receive, pilotGrid, cfg, method, noise_var, H_ideal)
%ESTIMATECHANNELFROMPILOTS Estimate the physical MIMO channel from pilot tones.

    if nargin < 4 || isempty(method)
        method = 'LS';
    end
    if nargin < 5 || isempty(noise_var)
        noise_var = 0;
    end
    if nargin < 6
        H_ideal = [];
    end

    method = upper(char(method));
    observations = localExtractPilotObservations(Frame_receive, pilotGrid, cfg);
    H_est = complex(zeros(cfg.N_subcarrier, cfg.N_symbol, cfg.N_Tx, cfg.N_Rx));

    for itx = 1:cfg.N_Tx
        for irx = 1:cfg.N_Rx
            obs = observations{itx, irx};
            switch method
                case 'LS'
                    H_est(:, :, itx, irx) = localEstimateLsGrid(obs, cfg);
                case 'MMSE'
                    H_est(:, :, itx, irx) = localEstimateMmseGrid(obs, cfg, noise_var);
                case {'KALMAN', 'BAYESIAN'}
                    H_est(:, :, itx, irx) = localEstimateKalmanGrid(obs, cfg, noise_var);
                otherwise
                    error('不支持的信道估计方法: %s', method);
            end
        end
    end

    estimationInfo = struct();
    estimationInfo.method = method;
    estimationInfo.pilot_bins = cfg.index_pilot(:);
    estimationInfo.pilot_pattern = 'frequency_time_interpolation';
    estimationInfo.nmse = NaN;

    if ~isempty(H_ideal)
        H_ideal = localNormalizeIdealGrid(H_ideal, cfg);
        errorPower = mean(abs(H_est(:) - H_ideal(:)).^2);
        refPower = mean(abs(H_ideal(:)).^2);
        estimationInfo.nmse = errorPower / max(refPower, eps);
    end
end

function observations = localExtractPilotObservations(Frame_receive, pilotGrid, cfg)
    observations = cell(cfg.N_Tx, cfg.N_Rx);

    for itx = 1:cfg.N_Tx
        pilotMaskTx = abs(pilotGrid(:, :, itx)) > 0;
        pilotBinsTx = find(any(pilotMaskTx, 2));
        if isempty(pilotBinsTx)
            error('Tx%d has no active pilots.', itx);
        end

        activeSymbols = find(any(pilotMaskTx, 1));
        for irx = 1:cfg.N_Rx
            pilotObs = complex(nan(numel(pilotBinsTx), cfg.N_symbol));
            for isym = activeSymbols
                activeBins = pilotMaskTx(:, isym);
                bins = find(activeBins);
                if isempty(bins)
                    continue;
                end
                pilotValues = squeeze(pilotGrid(bins, isym, itx));
                receivedValues = squeeze(Frame_receive(bins, isym, irx));
                [~, loc] = ismember(bins, pilotBinsTx);
                pilotObs(loc, isym) = receivedValues ./ pilotValues;
            end

            observations{itx, irx} = struct( ...
                'pilot_bins', pilotBinsTx(:), ...
                'pilot_obs', pilotObs, ...
                'symbol_indices', activeSymbols(:));
        end
    end
end

function H_grid = localEstimateLsGrid(obs, cfg)
    perSymbol = complex(nan(cfg.N_subcarrier, cfg.N_symbol));
    observedMask = any(~isnan(obs.pilot_obs), 1);
    for isym = find(observedMask)
        pilotValues = obs.pilot_obs(:, isym);
        perSymbol(:, isym) = interp1(obs.pilot_bins, pilotValues, ...
            (1:cfg.N_subcarrier).', cfg.pilot_interpolation, 'extrap');
    end
    H_grid = localInterpolateAcrossTime(perSymbol, cfg, false, 0);
end

function H_grid = localEstimateMmseGrid(obs, cfg, noise_var)
    perSymbol = complex(nan(cfg.N_subcarrier, cfg.N_symbol));
    observedMask = any(~isnan(obs.pilot_obs), 1);
    corrBins = localFrequencyCorrelation(cfg);
    reg = localObservationNoise(cfg, noise_var);

    for isym = find(observedMask)
        perSymbol(:, isym) = localMmseFrequencyInterp( ...
            obs.pilot_bins, obs.pilot_obs(:, isym), cfg.N_subcarrier, corrBins, reg);
    end

    H_grid = localInterpolateAcrossTime(perSymbol, cfg, true, reg);
end

function H_grid = localEstimateKalmanGrid(obs, cfg, noise_var)
    corrBins = localFrequencyCorrelation(cfg);
    reg = localObservationNoise(cfg, noise_var) * cfg.kalman_measurement_scale;
    rho = localTrackingCorrelation(cfg);
    processVar = cfg.kalman_process_scale * max(1 - abs(rho)^2, 1e-4);

    trackedPilots = complex(zeros(numel(obs.pilot_bins), cfg.N_symbol));
    for ibin = 1:numel(obs.pilot_bins)
        trackedPilots(ibin, :) = localKalmanTrack( ...
            obs.pilot_obs(ibin, :), rho, processVar, reg, cfg.kalman_initial_variance);
    end

    H_grid = complex(zeros(cfg.N_subcarrier, cfg.N_symbol));
    for isym = 1:cfg.N_symbol
        H_grid(:, isym) = localMmseFrequencyInterp( ...
            obs.pilot_bins, trackedPilots(:, isym), cfg.N_subcarrier, corrBins, reg);
    end
end

function H_interp = localInterpolateAcrossTime(perSymbol, cfg, useMmse, reg)
    H_interp = perSymbol;
    observedSymbols = find(any(~isnan(perSymbol), 1));
    if isempty(observedSymbols)
        error('No pilot-bearing OFDM symbols available for time interpolation.');
    end
    if numel(observedSymbols) == 1
        H_interp = repmat(perSymbol(:, observedSymbols), 1, cfg.N_symbol);
        return;
    end

    for isub = 1:cfg.N_subcarrier
        obsValues = perSymbol(isub, observedSymbols).';
        if useMmse
            H_interp(isub, :) = localMmseTimeInterp( ...
                observedSymbols(:), obsValues, cfg.N_symbol, cfg, reg);
        else
            H_interp(isub, :) = interp1(observedSymbols, obsValues, ...
                1:cfg.N_symbol, cfg.pilot_time_interpolation, 'extrap');
        end
    end
end

function H_full = localMmseFrequencyInterp(pilotBins, pilotValues, Nsubcarrier, corrBins, reg)
    pilotBins = pilotBins(:);
    pilotValues = pilotValues(:);
    allBins = (1:Nsubcarrier).';
    Rpp = exp(-abs(pilotBins - pilotBins.') / max(corrBins, 1));
    Rfp = exp(-abs(allBins - pilotBins.') / max(corrBins, 1));
    H_full = Rfp * ((Rpp + reg * eye(numel(pilotBins))) \ pilotValues);
end

function H_time = localMmseTimeInterp(observedSymbols, obsValues, Nsymbol, cfg, reg)
    allSymbols = (1:Nsymbol).';
    corrSym = localTimeCorrelationBins(cfg);
    Rtt = exp(-abs(observedSymbols - observedSymbols.') / max(corrSym, 1));
    Rat = exp(-abs(allSymbols - observedSymbols.') / max(corrSym, 1));
    H_time = (Rat * ((Rtt + reg * eye(numel(observedSymbols))) \ obsValues)).';
end

function tracked = localKalmanTrack(observations, rho, processVar, measVar, initialVar)
    tracked = complex(zeros(1, numel(observations)));
    x_prev = 0;
    P_prev = initialVar;

    for isym = 1:numel(observations)
        x_pred = rho * x_prev;
        P_pred = abs(rho)^2 * P_prev + processVar;

        if ~isnan(observations(isym))
            K = P_pred / (P_pred + measVar);
            x_post = x_pred + K * (observations(isym) - x_pred);
            P_post = (1 - K) * P_pred;
        else
            x_post = x_pred;
            P_post = P_pred;
        end

        tracked(isym) = x_post;
        x_prev = x_post;
        P_prev = max(real(P_post), eps);
    end
end

function H_ideal = localNormalizeIdealGrid(H_ideal, cfg)
    if ndims(H_ideal) == 2
        if cfg.N_Tx == 1 && cfg.N_Rx == 1 && size(H_ideal, 2) == cfg.N_symbol
            H_ideal = reshape(H_ideal, cfg.N_subcarrier, cfg.N_symbol, 1, 1);
        else
            H_ideal = reshape(H_ideal, cfg.N_subcarrier, 1, cfg.N_Tx, cfg.N_Rx);
            H_ideal = repmat(H_ideal, 1, cfg.N_symbol, 1, 1);
        end
    elseif ndims(H_ideal) == 3
        sz = size(H_ideal);
        if cfg.N_Rx == 1 && sz(2) == cfg.N_symbol && sz(3) == cfg.N_Tx
            H_ideal = reshape(H_ideal, cfg.N_subcarrier, cfg.N_symbol, cfg.N_Tx, 1);
        elseif cfg.N_Tx == 1 && sz(2) == cfg.N_symbol && sz(3) == cfg.N_Rx
            H_ideal = reshape(H_ideal, cfg.N_subcarrier, cfg.N_symbol, 1, cfg.N_Rx);
        else
            H_ideal = repmat(reshape(H_ideal, cfg.N_subcarrier, 1, cfg.N_Tx, cfg.N_Rx), ...
                1, cfg.N_symbol, 1, 1);
        end
    elseif ndims(H_ideal) ~= 4
        error('H_ideal must be Nsubcarrier x NTx x NRx or Nsubcarrier x Nsymbol x NTx x NRx.');
    end
end

function corrBins = localFrequencyCorrelation(cfg)
    if ~isempty(cfg.estimation_correlation_bins)
        corrBins = cfg.estimation_correlation_bins;
        return;
    end

    subcarrierSpacing = cfg.f_sample / cfg.N_subcarrier;
    coherenceBandwidth = 1 / max(5 * cfg.delay_spread_s, eps);
    corrBins = max(coherenceBandwidth / max(subcarrierSpacing, eps), 1);
end

function corrSymbols = localTimeCorrelationBins(cfg)
    if ~isempty(cfg.estimation_correlation_symbols)
        corrSymbols = cfg.estimation_correlation_symbols;
        return;
    end

    if cfg.max_doppler_hz <= 0
        corrSymbols = cfg.N_symbol;
        return;
    end

    coherenceTime = 1 / max(2 * pi * cfg.max_doppler_hz, eps);
    corrSymbols = max(coherenceTime / max(cfg.symbol_duration_s, eps), 1);
end

function measNoise = localObservationNoise(cfg, noise_var)
    measNoise = max(real(noise_var), 0) / max(abs(cfg.pilot_amplitude)^2, eps);
end

function rho = localTrackingCorrelation(cfg)
    if cfg.max_doppler_hz <= 0
        rho = cfg.dynamic_fading_correlation;
    else
        rho = besselj(0, 2 * pi * cfg.max_doppler_hz * cfg.symbol_duration_s);
    end
    if ~isfinite(rho)
        rho = cfg.dynamic_fading_correlation;
    end
    rho = min(max(real(rho), 0), 0.9999);
end
