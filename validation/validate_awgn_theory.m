function theory = validate_awgn_theory(output_dir, show_figures)
%VALIDATE_AWGN_THEORY Compare uncoded BPSK/QPSK BER against theory.

    rng(20260310, 'twister');
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    EbN0s_dB = 0:2:12;
    numBits = 4e5;

    [bpsk_emp, bpsk_theory] = local_simulate_awgn_theory(EbN0s_dB, numBits, 1);
    [qpsk_emp, qpsk_theory] = local_simulate_awgn_theory(EbN0s_dB, numBits, 2);

    figure_visibility = 'off';
    if show_figures
        figure_visibility = 'on';
    end

    fig = figure('Color', 'w', 'Visible', figure_visibility);
    semilogy(EbN0s_dB, bpsk_emp, 'o-', 'LineWidth', 1.5, 'MarkerSize', 7); hold on;
    semilogy(EbN0s_dB, bpsk_theory, '--', 'LineWidth', 1.5);
    semilogy(EbN0s_dB, qpsk_emp, 's-', 'LineWidth', 1.5, 'MarkerSize', 7);
    semilogy(EbN0s_dB, qpsk_theory, '--', 'LineWidth', 1.5);
    grid on;
    xlabel('Eb/N0 (dB)');
    ylabel('BER');
    legend('BPSK empirical', 'BPSK theory', 'QPSK empirical', 'QPSK theory', 'Location', 'southwest');
    title('AWGN BPSK/QPSK BER vs theory');

    figure_path = fullfile(output_dir, 'awgn_bpsk_qpsk_theory.png');
    exportgraphics(fig, figure_path, 'Resolution', 200);
    close(fig);

    theory = struct();
    theory.EbN0s_dB = EbN0s_dB;
    theory.bpsk.empirical = bpsk_emp;
    theory.bpsk.theory = bpsk_theory;
    theory.bpsk.max_abs_error = max(abs(bpsk_emp - bpsk_theory));
    theory.qpsk.empirical = qpsk_emp;
    theory.qpsk.theory = qpsk_theory;
    theory.qpsk.max_abs_error = max(abs(qpsk_emp - qpsk_theory));
    theory.figure_path = figure_path;
end

function [empiricalBER, theoryBER] = local_simulate_awgn_theory(EbN0s_dB, numBits, modOrder)
    numBits = floor(numBits / modOrder) * modOrder;
    tx_bits = randi([0 1], numBits, 1);
    tx_symbols = SymbolModulator(reshape(tx_bits, modOrder, []));

    empiricalBER = zeros(size(EbN0s_dB));
    theoryBER = qfunc(sqrt(2 * 10.^(EbN0s_dB / 10)));

    for i = 1:numel(EbN0s_dB)
        EbN0 = 10^(EbN0s_dB(i) / 10);
        noise_var = 1 / (modOrder * EbN0);
        rx_symbols = tx_symbols + sqrt(noise_var / 2) * ...
            (randn(size(tx_symbols)) + 1i * randn(size(tx_symbols)));
        rx_bits = SymbolDemodulator(rx_symbols, modOrder);
        empiricalBER(i) = mean(rx_bits(:) ~= tx_bits);
    end
end
