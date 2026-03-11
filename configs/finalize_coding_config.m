function cfg = finalize_coding_config(cfg)
%FINALIZE_CODING_CONFIG Derive coding-related frame lengths and objects.

    switch upper(cfg.Coded_method)
        case 'NULL'
            maxPayloadBits = cfg.frame_capacity_bits;
            cfg.payload_info_bits = localResolveRequestedPayloadBits(cfg, maxPayloadBits);
            cfg.valid_coded_bits = cfg.payload_info_bits;
            cfg.pad_bits = cfg.frame_capacity_bits - cfg.valid_coded_bits;
            cfg.R_code_eff = 1;
            cfg.packet_padding_info_bits = 0;

        case 'CONV'
            cfg.conv_trellis = SelectTrellis(cfg.code_rate);
            maxPayloadBits = local_max_conv_input_bits( ...
                cfg.frame_capacity_bits, cfg.conv_trellis, cfg.code_rate);
            cfg.payload_info_bits = localResolveRequestedPayloadBits(cfg, maxPayloadBits);
            cfg.valid_coded_bits = local_predict_conv_length( ...
                cfg.payload_info_bits, cfg.conv_trellis, cfg.code_rate);
            cfg.pad_bits = cfg.frame_capacity_bits - cfg.valid_coded_bits;
            cfg.R_code_eff = cfg.payload_info_bits / max(cfg.valid_coded_bits, 1);
            cfg.packet_padding_info_bits = 0;

        case 'RS'
            coded_block = cfg.rs_n * cfg.rs_m;
            info_block = cfg.rs_k * cfg.rs_m;
            maxBlocks = floor(cfg.frame_capacity_bits / coded_block);
            if maxBlocks < 1
                error('单帧容量不足以容纳一个完整RS码字。');
            end

            maxPayloadBits = maxBlocks * info_block;
            cfg.payload_info_bits = localResolveRequestedPayloadBits(cfg, maxPayloadBits);
            cfg.rs_num_blocks = max(1, ceil(cfg.payload_info_bits / info_block));
            cfg.valid_coded_bits = cfg.rs_num_blocks * coded_block;
            cfg.pad_bits = cfg.frame_capacity_bits - cfg.valid_coded_bits;
            cfg.R_code_eff = cfg.payload_info_bits / max(cfg.valid_coded_bits, 1);
            cfg.packet_padding_info_bits = cfg.rs_num_blocks * info_block - cfg.payload_info_bits;

        case 'LDPC'
            load(cfg.ldpc_matrix_path, 'H_parity');
            if ~issparse(H_parity)
                H_parity = sparse(H_parity);
            end

            [m, n] = size(H_parity);
            cfg.ldpc_H = H_parity;
            cfg.ldpc_k = n - m;
            cfg.ldpc_n = n;
            [cfg.hEnc, cfg.hDec] = CreateLDPCObjects(H_parity, cfg.ldpc_max_iterations);

            maxBlocks = floor(cfg.frame_capacity_bits / cfg.ldpc_n);
            if maxBlocks < 1
                error('单帧容量不足以容纳一个完整LDPC码字。');
            end

            if cfg.enable_finite_blocklength
                maxPayloadBits = maxBlocks * cfg.ldpc_k;
                cfg.payload_info_bits = localResolveRequestedPayloadBits(cfg, maxPayloadBits);
                cfg.ldpc_num_blocks = max(1, ceil(cfg.payload_info_bits / cfg.ldpc_k));
                cfg.ldpc_tail_bits = 0;
                cfg.valid_coded_bits = cfg.ldpc_num_blocks * cfg.ldpc_n;
                cfg.pad_bits = cfg.frame_capacity_bits - cfg.valid_coded_bits;
                cfg.R_code_eff = cfg.payload_info_bits / max(cfg.valid_coded_bits, 1);
                cfg.packet_padding_info_bits = cfg.ldpc_num_blocks * cfg.ldpc_k - cfg.payload_info_bits;
                cfg.ldpc_packet_mode = 'padded';
            else
                cfg.ldpc_num_blocks = floor(cfg.frame_capacity_bits / cfg.ldpc_n);
                remaining_capacity = cfg.frame_capacity_bits - cfg.ldpc_num_blocks * cfg.ldpc_n;
                cfg.ldpc_tail_bits = min(remaining_capacity, cfg.ldpc_k - 1);
                cfg.payload_info_bits = cfg.ldpc_num_blocks * cfg.ldpc_k + cfg.ldpc_tail_bits;
                cfg.valid_coded_bits = cfg.ldpc_num_blocks * cfg.ldpc_n + cfg.ldpc_tail_bits;
                cfg.pad_bits = cfg.frame_capacity_bits - cfg.valid_coded_bits;
                cfg.R_code_eff = cfg.payload_info_bits / max(cfg.valid_coded_bits, 1);
                cfg.packet_padding_info_bits = 0;
                cfg.ldpc_packet_mode = 'legacy';
            end

        otherwise
            error('不支持的编码方式: %s', cfg.Coded_method);
    end

    cfg.requested_bits_per_packet = cfg.payload_info_bits;
    cfg.info_bits_per_user = repmat(cfg.payload_info_bits, 1, cfg.N_user);
end

function payloadBits = localResolveRequestedPayloadBits(cfg, maxPayloadBits)
    requestedBits = maxPayloadBits;
    if isfield(cfg, 'N_bits_per_packet') && ~isempty(cfg.N_bits_per_packet)
        requestedBits = floor(cfg.N_bits_per_packet);
    end

    if ~isscalar(requestedBits) || requestedBits < 1
        error('N_bits_per_packet必须是正标量。');
    end
    if requestedBits > maxPayloadBits
        error('请求的packet长度%d超过当前配置可支持的最大信息比特数%d。', ...
            requestedBits, maxPayloadBits);
    end

    payloadBits = requestedBits;
end

function info_bits = local_max_conv_input_bits(frame_capacity_bits, trellis, code_rate)
    switch code_rate
        case 1/2
            info_bits = floor(frame_capacity_bits / 2);
        case 1/3
            info_bits = floor(frame_capacity_bits / 3);
        case 2/3
            info_bits = 2 * floor(frame_capacity_bits / 3);
        case 3/4
            info_bits = 3 * floor(frame_capacity_bits / 4);
        otherwise
            error('不支持的卷积码率。');
    end

    while local_predict_conv_length(info_bits, trellis, code_rate) > frame_capacity_bits
        info_bits = info_bits - 1;
    end
end

function coded_len = local_predict_conv_length(info_bits, trellis, code_rate)
    if info_bits == 0
        coded_len = 0;
        return;
    end

    coded_len = length(ConvEncode(false(info_bits, 1), trellis, code_rate));
end
