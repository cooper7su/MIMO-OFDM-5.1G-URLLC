function decoded_bits = ConvDecode(Frame_demod, trellis, code_rate)
%CONVDECODE Hard-decision Viterbi decoding for supported code rates.

    switch code_rate
        case {1/2, 1/3}
            decoded_bits = vitdec(Frame_demod, trellis, 34, 'trunc', 'hard');
        case 2/3
            punct_pattern = [1; 1; 1; 0];
            decoded_bits = vitdec(Frame_demod, trellis, 34, 'trunc', 'hard', punct_pattern);
        case 3/4
            punct_pattern = [1; 1; 1; 0; 1; 0];
            decoded_bits = vitdec(Frame_demod, trellis, 34, 'trunc', 'hard', punct_pattern);
        otherwise
            error('不支持的码率。');
    end
end
