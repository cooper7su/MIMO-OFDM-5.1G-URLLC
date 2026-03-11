function entry = encode_bits(bits, cfg)
%ENCODE_BITS Apply the coding method configured in cfg to one user payload.

    bits = bits(:);

    switch upper(cfg.Coded_method)
        case 'NULL'
            entry.data = bits;
            entry.num = numel(bits);
            entry.original_length = numel(bits);
            entry.coded_indices = [];

        case 'CONV'
            coded_bits = ConvEncode(bits, cfg.conv_trellis, cfg.code_rate);
            entry.data = coded_bits(:);
            entry.num = numel(coded_bits);
            entry.original_length = numel(bits);
            entry.coded_indices = [];

        case 'RS'
            coded_bits = RS_Encode(bits, cfg.rs_n, cfg.rs_k, cfg.rs_m);
            entry.data = coded_bits(:);
            entry.num = numel(coded_bits);
            entry.original_length = numel(bits);
            entry.coded_indices = [];

        case 'LDPC'
            [coded_bits, original_length, coded_meta] = LDPC_Encode( ...
                bits, cfg.hEnc, cfg.ldpc_k, cfg.ldpc_packet_mode);
            entry.data = coded_bits(:);
            entry.num = numel(coded_bits);
            entry.original_length = original_length;
            entry.coded_indices = coded_meta.coded_indices;
            entry.coded_meta = coded_meta;

        otherwise
            error('不支持的编码方式: %s', cfg.Coded_method);
    end

    if entry.num > cfg.frame_capacity_bits
        error('编码后长度%d超过单帧映射容量%d。', entry.num, cfg.frame_capacity_bits);
    end
end
