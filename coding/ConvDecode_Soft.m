function decoded_bits = ConvDecode_Soft(llr, trellis, code_rate)
% 多速率软判决维特比解码，输入LLR正值偏向比特1。

    % vitdec('unquant')中，较大的度量更偏向比特0，因此对LLR取负。
    llr = -llr(:).';
    tb_depth = 34;

    switch code_rate
        case {1/2, 1/3}
            decoded_bits = vitdec(llr, trellis, tb_depth, 'trunc', 'unquant');
        case 2/3
            punct_pattern = [1; 1; 1; 0];
            decoded_bits = vitdec(llr, trellis, tb_depth, 'trunc', 'unquant', punct_pattern);
        case 3/4
            punct_pattern = [1; 1; 1; 0; 1; 0];
            decoded_bits = vitdec(llr, trellis, tb_depth, 'trunc', 'unquant', punct_pattern);
        otherwise
            error('不支持的码率');
    end

    decoded_bits = decoded_bits(:);
end
