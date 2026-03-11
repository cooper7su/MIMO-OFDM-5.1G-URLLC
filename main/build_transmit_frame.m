function frame = build_transmit_frame(cfg)
%BUILD_TRANSMIT_FRAME Assemble one encoded OFDM/STBC transmit frame.

    frame_bits = FrameBitGenerator( ...
        cfg.N_data, cfg.N_user, cfg.N_mod, cfg.N_symbol, cfg.info_bits_per_user);
    coded_bits = cell(1, cfg.N_user);

    for iuser = 1:cfg.N_user
        coded_bits{iuser} = encode_bits(frame_bits(iuser).data, cfg);
    end

    [index_data_per_user, padded_bits] = SubcarrierAllocation( ...
        coded_bits, cfg.index_data, cfg.N_data, cfg.N_user, cfg.N_symbol, ...
        cfg.N_mod, "neighbour", cfg.code_rate, cfg.Coded_method);

    frame_mod = Modulator( ...
        padded_bits, index_data_per_user, cfg.N_data, cfg.N_user, ...
        cfg.N_symbol, cfg.N_mod, cfg.N_subcarrier);
    frame_stbc = STBCCoding(frame_mod, cfg);
    [frame_pilot, pilot_grid, pilot_info] = AddPilot(frame_stbc, cfg);
    frame_transmit = OFDMModulator( ...
        frame_pilot, cfg.N_sym, cfg.N_subcarrier, cfg.N_symbol, cfg.N_Tx, cfg.N_GI);

    frame = struct();
    frame.Frame_bit = frame_bits;
    frame.Frame_bit_coded = coded_bits;
    frame.index_data_per_user = index_data_per_user;
    frame.Pilot_grid = pilot_grid;
    frame.pilot_info = pilot_info;
    frame.Frame_transmit = frame_transmit;
end
