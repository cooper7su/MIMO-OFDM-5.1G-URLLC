function [coded_bits, original_length, coded_meta] = LDPC_Encode(input_bits, hEnc, ldpc_k, packet_mode)
%LDPC_ENCODE Encode LDPC blocks in legacy or padded finite-blocklength mode.

    if nargin < 4 || isempty(packet_mode)
        packet_mode = 'legacy';
    end

    original_length = length(input_bits);
    input_bits = double(input_bits(:));

    switch lower(packet_mode)
        case 'legacy'
            num_full_blocks = floor(original_length / ldpc_k);
            num_to_code = num_full_blocks * ldpc_k;
            coded_blocks = [];

            for i = 1:num_full_blocks
                start_idx = (i - 1) * ldpc_k + 1;
                end_idx = i * ldpc_k;
                block = input_bits(start_idx:end_idx);
                coded_blocks = [coded_blocks; step(hEnc, block)]; %#ok<AGROW>
            end

            uncoded_bits = input_bits(num_to_code + 1:end);
            coded_bits = [coded_blocks; uncoded_bits];
            coded_meta = struct( ...
                'strategy', 'legacy', ...
                'coded_indices', (1:num_to_code).', ...
                'num_blocks', num_full_blocks, ...
                'padded_input_length', num_to_code, ...
                'coded_length', numel(coded_bits), ...
                'uncoded_length', numel(uncoded_bits));

        case 'padded'
            num_blocks = max(1, ceil(original_length / ldpc_k));
            padded_input_length = num_blocks * ldpc_k;
            padded_bits = [input_bits; zeros(padded_input_length - original_length, 1)];
            coded_bits = [];

            for i = 1:num_blocks
                start_idx = (i - 1) * ldpc_k + 1;
                end_idx = i * ldpc_k;
                block = padded_bits(start_idx:end_idx);
                coded_bits = [coded_bits; step(hEnc, block)]; %#ok<AGROW>
            end

            coded_meta = struct( ...
                'strategy', 'padded', ...
                'coded_indices', (1:original_length).', ...
                'num_blocks', num_blocks, ...
                'padded_input_length', padded_input_length, ...
                'coded_length', numel(coded_bits), ...
                'uncoded_length', 0);

        otherwise
            error('不支持的LDPC packet mode: %s', packet_mode);
    end
end
