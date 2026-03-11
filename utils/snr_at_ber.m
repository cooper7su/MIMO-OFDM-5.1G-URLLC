function snr = snr_at_ber(snr_dB_vec, ber_vec, target_ber)
%SNR_AT_BER Interpolate the Eb/N0 needed to reach target BER.

    snr = Inf;
    for j = 2:numel(snr_dB_vec)
        y1 = ber_vec(j - 1);
        y2 = ber_vec(j);
        if y1 > target_ber && y2 <= target_ber
            x1 = snr_dB_vec(j - 1);
            x2 = snr_dB_vec(j);
            snr = x1 + (target_ber - y1) * (x2 - x1) / (y2 - y1);
            return;
        end
    end
end
