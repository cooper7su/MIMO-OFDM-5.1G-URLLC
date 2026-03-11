function figure_path = save_ber_curve_plot(EbN0s_dB, BER, cfg)
%SAVE_BER_CURVE_PLOT Export the BER curve for one scenario.
    figure_path = save_metric_curve_plot(EbN0s_dB, struct('label', 'PRIMARY', 'values', BER), ...
        cfg, 'BER', 'BER', 'semilogy', [1e-5, 1]);
end
