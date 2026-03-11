function H_virtual = CompressToSTBCChannel(H_physical, cfg)
%COMPRESSTOSTBCCHANNEL Map physical Tx channels to virtual STBC streams.

    weights = cfg.stbc.group_weights;

    if ndims(H_physical) == 2
        if cfg.N_Tx == 1 && cfg.N_Rx == 1 && size(H_physical, 2) == cfg.N_symbol
            H_physical = reshape(H_physical, size(H_physical, 1), cfg.N_symbol, 1, 1);
        else
            H_physical = reshape(H_physical, size(H_physical, 1), 1, cfg.N_Tx, cfg.N_Rx);
        end
    elseif ndims(H_physical) == 3
        sz = size(H_physical);
        if cfg.N_Rx == 1 && sz(2) == cfg.N_symbol && sz(3) == cfg.N_Tx
            H_physical = reshape(H_physical, size(H_physical, 1), cfg.N_symbol, cfg.N_Tx, 1);
        elseif cfg.N_Tx == 1 && sz(2) == cfg.N_symbol && sz(3) == cfg.N_Rx
            H_physical = reshape(H_physical, size(H_physical, 1), cfg.N_symbol, 1, cfg.N_Rx);
        else
            H_physical = reshape(H_physical, size(H_physical, 1), 1, cfg.N_Tx, cfg.N_Rx);
        end
    elseif ndims(H_physical) ~= 4
        error('H_physical must be Nsubcarrier x NTx x NRx or Nsubcarrier x Nsymbol x NTx x NRx.');
    end

    N_subcarrier = size(H_physical, 1);
    N_symbol = size(H_physical, 2);
    N_Rx = size(H_physical, 4);
    H_virtual = complex(zeros(N_subcarrier, N_symbol, cfg.stbc.num_streams, N_Rx));

    for irx = 1:N_Rx
        for isym = 1:N_symbol
            H_virtual(:, isym, :, irx) = squeeze(H_physical(:, isym, :, irx)) * weights;
        end
    end

    if N_symbol == 1
        H_virtual = reshape(H_virtual, N_subcarrier, cfg.stbc.num_streams, N_Rx);
    end
end
