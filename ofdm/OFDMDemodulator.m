function Frame_recieve = OFDMDemodulator(Frame_noise, N_sym, N_subcarrier, N_symbol, N_Rx, N_GI)
%OFDMDemodulator Recover the frequency-domain resource grid from each Rx antenna.

    Frame_recieve = zeros(N_subcarrier, N_symbol, N_Rx);

    for iant = 1:N_Rx
        Frame_symbol = reshape(Frame_noise(1, :, iant), N_sym, N_symbol);
        Frame_noGI = Frame_symbol(N_GI + 1:end, :);
        Frame_recieve(:, :, iant) = fftshift(fft(Frame_noGI, N_subcarrier, 1) / sqrt(N_subcarrier), 1);
    end
end
