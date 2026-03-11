function coded_bits = ConvEncode(input_bits, trellis, code_rate)
% 支持不同码率的卷积编码
switch code_rate
    case {1/2, 1/3}
        % 直接编码
        coded_bits = convenc(input_bits, trellis);
    case 2/3
        % 打孔模式：保留每4位中的3位
        punct_pattern = [1;1;1;0]; % 打孔模式
        coded_bits = convenc(input_bits, trellis, punct_pattern);
    case 3/4
        % 打孔模式：保留每6位中的4位
        punct_pattern = [1;1;1;0;1;0];
        coded_bits = convenc(input_bits, trellis, punct_pattern);
    otherwise
        error('不支持的码率');
end
end