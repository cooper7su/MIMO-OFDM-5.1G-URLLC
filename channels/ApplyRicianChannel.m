function [Frame_channel, H_freq, channel_info] = ApplyRicianChannel(Frame_transmit, cfg)
%APPLYRICIANCHANNEL Apply a flat Rician MIMO fading channel to one frame.
%   Noise is added separately in RUN_FRAME_CHANNEL to preserve the Phase 1
%   channel/noise split and keep Eb/N0 handling centralized.

    N_samples = size(Frame_transmit, 2);
    K_linear = cfg.K_factor;
    losScale = sqrt(K_linear / (K_linear + 1));
    scatterScale = sqrt(1 / (K_linear + 1));

    Frame_channel = complex(zeros(1, N_samples, cfg.N_Rx));
    H_freq = complex(zeros(cfg.N_subcarrier, cfg.N_Tx, cfg.N_Rx));
    channel_matrix = complex(zeros(cfg.N_Tx, cfg.N_Rx));
    los_component = complex(zeros(cfg.N_Tx, cfg.N_Rx));
    scatter_component = complex(zeros(cfg.N_Tx, cfg.N_Rx));

    for irx = 1:cfg.N_Rx
        rx_signal = zeros(1, N_samples);
        for itx = 1:cfg.N_Tx
            tx_signal = reshape(Frame_transmit(1, :, itx), 1, []);
            losTerm = exp(1i * 2 * pi * rand(1));
            scatterTerm = (randn(1) + 1i * randn(1)) / sqrt(2);
            hFlat = losScale * losTerm + scatterScale * scatterTerm;

            rx_signal = rx_signal + hFlat * tx_signal;
            H_freq(:, itx, irx) = hFlat * ones(cfg.N_subcarrier, 1);
            channel_matrix(itx, irx) = hFlat;
            los_component(itx, irx) = losScale * losTerm;
            scatter_component(itx, irx) = scatterScale * scatterTerm;
        end
        Frame_channel(1, :, irx) = rx_signal;
    end

    channel_info = struct();
    channel_info.channel_model = 'RICIAN';
    channel_info.K_factor = K_linear;
    channel_info.channel_matrix = channel_matrix;
    channel_info.los_component = los_component;
    channel_info.scatter_component = scatter_component;
    channel_info.tap_delays = 0;
    channel_info.tap_powers = 1;
    channel_info.channel_taps = reshape(channel_matrix, [1, cfg.N_Tx, cfg.N_Rx]);
end
