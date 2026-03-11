function [Frame_decoded, effective_noise_var] = STBCDecoding(Frame_recieve, H, varargin)
%STBCDECODING Perform single-stream or Alamouti combining with optional MMSE normalization.

    equalizer_type = 'ZF';
    numeric_args = [];
    for iarg = 1:numel(varargin)
        if ischar(varargin{iarg}) || isstring(varargin{iarg})
            equalizer_type = char(varargin{iarg});
        else
            numeric_args(end + 1) = varargin{iarg}; %#ok<AGROW>
        end
    end

    if numel(numeric_args) == 4
        noise_var = 0;
        N_subcarrier = numeric_args(1);
        N_Tx = numeric_args(2);
        N_Rx = numeric_args(3);
        N_symbol = numeric_args(4);
    elseif numel(numeric_args) == 5
        noise_var = numeric_args(1);
        N_subcarrier = numeric_args(2);
        N_Tx = numeric_args(3);
        N_Rx = numeric_args(4);
        N_symbol = numeric_args(5);
    else
        error('STBCDecoding输入参数数量不正确');
    end

    H = localNormalizeChannelGrid(H, N_subcarrier, N_symbol, N_Tx, N_Rx);
    Frame_decoded = zeros(N_subcarrier, N_symbol);
    effective_noise_var = zeros(N_subcarrier, N_symbol);
    noise_var = max(real(noise_var), 0);

    if N_Tx == 1
        for isym = 1:N_symbol
            signal_norm = zeros(N_subcarrier, 1);
            combined = zeros(N_subcarrier, 1);
            for irx = 1:N_Rx
                h = squeeze(H(:, isym, 1, irx));
                combined = combined + conj(h) .* Frame_recieve(:, isym, irx);
                signal_norm = signal_norm + abs(h).^2;
            end
            denom = localEqualizerDenominator(signal_norm, noise_var, equalizer_type);
            Frame_decoded(:, isym) = combined ./ max(denom, eps);
            effective_noise_var(:, isym) = localEffectiveNoise(signal_norm, noise_var, denom);
        end
        return;
    end

    if N_Tx ~= 2
        error('当前STBC解码仅支持1Tx或2Tx');
    end
    if mod(N_symbol, 2) ~= 0
        error('Alamouti解码要求N_symbol为偶数');
    end

    for ispace = 1:(N_symbol / 2)
        idx = 2 * ispace - 1;
        x1_num = zeros(N_subcarrier, 1);
        x2_num = zeros(N_subcarrier, 1);
        signal_norm = zeros(N_subcarrier, 1);

        for irx = 1:N_Rx
            h1 = squeeze(mean(H(:, idx:idx + 1, 1, irx), 2));
            h2 = squeeze(mean(H(:, idx:idx + 1, 2, irx), 2));
            r1 = Frame_recieve(:, idx, irx);
            r2 = Frame_recieve(:, idx + 1, irx);
            x1_num = x1_num + conj(h1) .* r1 + h2 .* conj(r2);
            x2_num = x2_num + conj(h2) .* r1 - h1 .* conj(r2);
            signal_norm = signal_norm + abs(h1).^2 + abs(h2).^2;
        end

        denom = localEqualizerDenominator(signal_norm, noise_var, equalizer_type);
        Frame_decoded(:, idx) = x1_num ./ max(denom, eps);
        Frame_decoded(:, idx + 1) = x2_num ./ max(denom, eps);
        effective_noise_var(:, idx:idx + 1) = repmat(localEffectiveNoise(signal_norm, noise_var, denom), 1, 2);
    end
end

function H = localNormalizeChannelGrid(H, N_subcarrier, N_symbol, N_Tx, N_Rx)
    if ndims(H) == 2
        if N_Tx == 1 && N_Rx == 1 && size(H, 2) == N_symbol
            H = reshape(H, N_subcarrier, N_symbol, 1, 1);
        else
            H = reshape(H, N_subcarrier, 1, N_Tx, N_Rx);
        end
    elseif ndims(H) == 3
        sz = size(H);
        if N_Rx == 1 && sz(2) == N_symbol && sz(3) == N_Tx
            H = reshape(H, N_subcarrier, N_symbol, N_Tx, 1);
        elseif N_Tx == 1 && sz(2) == N_symbol && sz(3) == N_Rx
            H = reshape(H, N_subcarrier, N_symbol, 1, N_Rx);
        else
            H = reshape(H, N_subcarrier, 1, N_Tx, N_Rx);
        end
    elseif ndims(H) ~= 4
        error('H must be 2D, 3D, or 4D.');
    end

    if size(H, 2) == 1
        H = repmat(H, 1, N_symbol, 1, 1);
    elseif size(H, 2) ~= N_symbol
        error('动态信道的符号维度与N_symbol不一致。');
    end
end

function denom = localEqualizerDenominator(signal_norm, noise_var, equalizer_type)
    if strcmpi(equalizer_type, 'MMSE')
        denom = signal_norm + noise_var;
    else
        denom = signal_norm;
    end
end

function effNoise = localEffectiveNoise(signal_norm, noise_var, denom)
    effNoise = noise_var .* signal_norm ./ max(abs(denom).^2, eps);
end
