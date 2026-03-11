function rx_frame = process_receive_frame(channel_state, tx_frame, cfg, csiMode)
%PROCESS_RECEIVE_FRAME Perform OFDM demodulation, STBC combining, and BER counting.

    if nargin < 4 || isempty(csiMode)
        csiMode = cfg.primary_csi_mode;
    end

    frame_receive = OFDMDemodulator( ...
        channel_state.Frame_rx, cfg.N_sym, cfg.N_subcarrier, cfg.N_symbol, cfg.N_Rx, cfg.N_GI);
    [channel_response, estimation_info] = localResolveChannelResponse( ...
        frame_receive, channel_state, tx_frame, cfg, csiMode);
    [frame_decoded, effective_noise_var] = STBCDecoding( ...
        frame_receive, channel_response, channel_state.noise_var, ...
        cfg.N_subcarrier, cfg.stbc.num_streams, cfg.N_Rx, cfg.N_symbol, cfg.equalizer_type);
    [frameErrors, frameBits, blockErrors, blockCount] = decode_frame_bits( ...
        frame_decoded, effective_noise_var, tx_frame, cfg);

    rx_frame = struct();
    rx_frame.csiMode = lower(csiMode);
    rx_frame.Frame_receive = frame_receive;
    rx_frame.Frame_decoded = frame_decoded;
    rx_frame.effective_noise_var = effective_noise_var;
    rx_frame.frameErrors = frameErrors;
    rx_frame.frameBits = frameBits;
    rx_frame.blockErrors = blockErrors;
    rx_frame.blockCount = blockCount;
    rx_frame.channel_response = channel_response;
    rx_frame.estimation_info = estimation_info;
end

function [channel_response, estimation_info] = localResolveChannelResponse( ...
        frame_receive, channel_state, tx_frame, cfg, csiMode)
    estimation_info = struct('mode', lower(csiMode), 'method', 'ideal', 'nmse', NaN);

    switch lower(csiMode)
        case 'ideal'
            channel_response = CompressToSTBCChannel(channel_state.H_freq, cfg);

        case 'estimated'
            [H_est_physical, estimation_info] = localEstimatePhysicalChannel( ...
                frame_receive, tx_frame.Pilot_grid, channel_state, cfg);
            channel_response = CompressToSTBCChannel(H_est_physical, cfg);
            H_ideal_virtual = CompressToSTBCChannel(channel_state.H_freq, cfg);
            estimation_info.nmse_virtual = localComputeVirtualNmse( ...
                channel_response, H_ideal_virtual);
            if (~isfield(estimation_info, 'nmse') || ~isfinite(estimation_info.nmse)) && ...
                    isfinite(estimation_info.nmse_virtual)
                estimation_info.nmse = estimation_info.nmse_virtual;
            end
            estimation_info.mode = 'estimated';

        otherwise
            error('不支持的CSI模式: %s', csiMode);
    end
end

function [H_est_physical, estimation_info] = localEstimatePhysicalChannel( ...
        frame_receive, pilot_grid, channel_state, cfg)
    method = upper(char(cfg.channel_estimation_method));
    switch method
        case 'LS'
            [H_est_physical, estimation_info] = EstimateChannelLS( ...
                frame_receive, pilot_grid, cfg, channel_state.noise_var, channel_state.H_freq);
        case 'MMSE'
            [H_est_physical, estimation_info] = EstimateChannelMMSE( ...
                frame_receive, pilot_grid, cfg, channel_state.noise_var, channel_state.H_freq);
        case 'KALMAN'
            [H_est_physical, estimation_info] = EstimateChannelKalman( ...
                frame_receive, pilot_grid, cfg, channel_state.noise_var, channel_state.H_freq);
        case 'BAYESIAN'
            [H_est_physical, estimation_info] = EstimateChannelBayesian( ...
                frame_receive, pilot_grid, cfg, channel_state.noise_var, channel_state.H_freq);
        otherwise
            error('不支持的信道估计方法: %s', cfg.channel_estimation_method);
    end
end

function nmseValue = localComputeVirtualNmse(H_est, H_ref)
    [H_est, H_ref, isAligned] = localAlignVirtualChannels(H_est, H_ref);
    if ~isAligned
        nmseValue = NaN;
        return;
    end

    errorPower = mean(abs(H_est(:) - H_ref(:)).^2);
    refPower = mean(abs(H_ref(:)).^2);
    nmseValue = errorPower / max(refPower, eps);
end

function [A, B, isAligned] = localAlignVirtualChannels(A, B)
    sizeA = size(A);
    sizeB = size(B);
    numDims = max(numel(sizeA), numel(sizeB));
    sizeA(end + 1:numDims) = 1;
    sizeB(end + 1:numDims) = 1;

    for idim = 1:numDims
        if sizeA(idim) == sizeB(idim)
            continue;
        end
        if sizeA(idim) == 1
            repVec = ones(1, numDims);
            repVec(idim) = sizeB(idim);
            A = repmat(A, repVec);
            sizeA(idim) = sizeB(idim);
        elseif sizeB(idim) == 1
            repVec = ones(1, numDims);
            repVec(idim) = sizeA(idim);
            B = repmat(B, repVec);
            sizeB(idim) = sizeA(idim);
        else
            isAligned = false;
            return;
        end
    end

    isAligned = true;
end
