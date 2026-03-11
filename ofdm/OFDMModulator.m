function Frame_transmit = OFDMModulator(Frame_pilot, N_sym, N_subcarrier, N_symbol, N_Tx, N_GI)
%OFDMMODULATOR Convert one frequency-domain frame into time-domain waveforms.

    Frame_transmit = zeros(1, N_sym * N_symbol, N_Tx);

    for iant = 1:N_Tx
        frame_td = sqrt(N_subcarrier) * ifft(fftshift(Frame_pilot(:, :, iant), 1));
        frame_cp = frame_td(N_subcarrier - N_GI + 1:N_subcarrier, :);
        frame_with_cp = [frame_cp; frame_td];
        Frame_transmit(:, :, iant) = reshape(frame_with_cp, 1, N_sym * N_symbol);
    end
end
