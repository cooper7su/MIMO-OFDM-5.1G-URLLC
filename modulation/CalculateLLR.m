function llr = CalculateLLR(received_signal, noise_var, mod_order, ~)
% 生成与SymbolDemodulator同序的比特LLR，正值偏向比特1。

    received_signal = received_signal(:).';
    if isscalar(noise_var)
        noise_var = repmat(noise_var, size(received_signal));
    else
        noise_var = noise_var(:).';
    end
    noise_var = max(real(noise_var), 1e-10);

    switch mod_order
        case 1
            llr = (2 * real(received_signal) ./ noise_var).';
        case 2
            llr_matrix = [ ...
                2 * real(received_signal) ./ noise_var; ...
                2 * imag(received_signal) ./ noise_var];
            llr = llr_matrix(:);
        otherwise
            error('当前软判决仅支持BPSK和QPSK');
    end
end
