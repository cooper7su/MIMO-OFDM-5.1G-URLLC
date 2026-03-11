function [frameErrors, frameBits, blockErrors, blockCount] = decode_frame_bits(frame_decoded, effective_noise_var, tx_frame, cfg)
%DECODE_FRAME_BITS Recover user bits and count frame-level BER statistics.

    frameErrors = 0;
    frameBits = 0;
    blockErrors = 0;
    blockCount = cfg.N_user;

    for iuser = 1:cfg.N_user
        data_symbols = frame_decoded(tx_frame.index_data_per_user{iuser}, :);
        data_noise_var = effective_noise_var(tx_frame.index_data_per_user{iuser}, :);
        symbol_stream = data_symbols(:);
        noise_stream = data_noise_var(:);
        entry = tx_frame.Frame_bit_coded{iuser};
        ref_bits = tx_frame.Frame_bit(iuser).data(:);

        switch upper(cfg.Coded_method)
            case 'NULL'
                llr = CalculateLLR(symbol_stream, noise_stream, cfg.N_mod);
                decoded_bits = llr(1:entry.original_length) > 0;

            case 'CONV'
                llr = CalculateLLR(symbol_stream, noise_stream, cfg.N_mod, cfg.code_rate);
                llr = llr(1:entry.num);
                if cfg.enable_soft_viterbi
                    decoded_bits = ConvDecode_Soft(llr, cfg.conv_trellis, cfg.code_rate);
                else
                    decoded_bits = ConvDecode(llr > 0, cfg.conv_trellis, cfg.code_rate);
                end
                decoded_bits = decoded_bits(1:entry.original_length);

            case 'RS'
                llr = CalculateLLR(symbol_stream, noise_stream, cfg.N_mod);
                hard_bits = double(llr(1:entry.num) > 0);
                decoded_bits = RS_Decode(hard_bits, cfg.rs_n, cfg.rs_k, cfg.rs_m, entry.original_length);

            case 'LDPC'
                llr = CalculateLLR(symbol_stream, noise_stream, cfg.N_mod);
                llr = llr(1:entry.num);
                coded_meta = entry.coded_indices;
                if isfield(entry, 'coded_meta') && ~isempty(entry.coded_meta)
                    coded_meta = entry.coded_meta;
                end
                decoded_bits = LDPC_Decode( ...
                    -llr, cfg.hDec, cfg.ldpc_n, cfg.ldpc_k, entry.original_length, coded_meta);

            otherwise
                error('不支持的编码方式: %s', cfg.Coded_method);
        end

        decoded_bits = logical(decoded_bits(:));
        userErrors = nnz(decoded_bits ~= ref_bits);
        frameErrors = frameErrors + userErrors;
        frameBits = frameBits + numel(ref_bits);
        blockErrors = blockErrors + double(userErrors > 0);
    end
end
