function decoded_bits = LDPC_Decode(received_llr, hDec, ldpc_n, ldpc_k, original_length, coded_meta)
%LDPC_DECODE Decode legacy or padded LDPC blocks and truncate to packet length.

    if nargin < 6 || isempty(coded_meta)
        coded_meta = struct('strategy', 'legacy', 'coded_indices', (1:original_length).');
    end
    if isnumeric(coded_meta)
        coded_meta = struct('strategy', 'legacy', 'coded_indices', coded_meta(:));
    end

    switch lower(coded_meta.strategy)
        case 'legacy'
            decoded_bits = localDecodeLegacy(received_llr, hDec, ldpc_n, ldpc_k, original_length, coded_meta);

        case 'padded'
            decoded_bits = localDecodePadded(received_llr, hDec, ldpc_n, ldpc_k, original_length, coded_meta);

        otherwise
            error('不支持的LDPC decode strategy: %s', coded_meta.strategy);
    end
end

function decoded_bits = localDecodeLegacy(received_llr, hDec, ldpc_n, ldpc_k, original_length, coded_meta)
    coded_indices = coded_meta.coded_indices(:);
    num_coded = length(coded_indices);
    decoded_bits = zeros(original_length, 1);

    non_coded_indices = setdiff(1:original_length, coded_indices);
    if ~isempty(non_coded_indices)
        start_idx = max(1, length(received_llr) - length(non_coded_indices) + 1);
        end_idx = length(received_llr);
        decoded_bits(non_coded_indices) = received_llr(start_idx:end_idx) < 0;
    end

    if num_coded > 0
        num_full_blocks = floor(num_coded / ldpc_k);
        remaining_bits = mod(num_coded, ldpc_k);
        decoded_coded = [];

        for i = 1:num_full_blocks
            start_idx = (i - 1) * ldpc_n + 1;
            end_idx = min(i * ldpc_n, length(received_llr));
            if start_idx > length(received_llr)
                break;
            end
            llr_block = localPadLLR(received_llr(start_idx:end_idx), ldpc_n);
            decoded_block = step(hDec, llr_block);
            decoded_coded = [decoded_coded; decoded_block]; %#ok<AGROW>
        end

        if remaining_bits > 0 && (num_full_blocks * ldpc_n + 1) <= length(received_llr)
            start_idx = num_full_blocks * ldpc_n + 1;
            end_idx = min(num_full_blocks * ldpc_n + ldpc_n, length(received_llr));
            llr_block = localPadLLR(received_llr(start_idx:end_idx), ldpc_n);
            decoded_block = step(hDec, llr_block);
            decoded_coded = [decoded_coded; decoded_block(1:remaining_bits)]; %#ok<AGROW>
        end

        if ~isempty(decoded_coded)
            useLength = min(num_coded, length(decoded_coded));
            decoded_bits(coded_indices(1:useLength)) = decoded_coded(1:useLength);
        end
    end
end

function decoded_bits = localDecodePadded(received_llr, hDec, ldpc_n, ldpc_k, original_length, coded_meta)
    num_blocks = coded_meta.num_blocks;
    decoded_stream = [];

    for i = 1:num_blocks
        start_idx = (i - 1) * ldpc_n + 1;
        end_idx = min(i * ldpc_n, length(received_llr));
        if start_idx > length(received_llr)
            break;
        end
        llr_block = localPadLLR(received_llr(start_idx:end_idx), ldpc_n);
        decoded_block = step(hDec, llr_block);
        decoded_stream = [decoded_stream; decoded_block(1:ldpc_k)]; %#ok<AGROW>
    end

    if isempty(decoded_stream)
        decoded_bits = zeros(original_length, 1);
    else
        decoded_bits = decoded_stream(1:min(original_length, length(decoded_stream)));
        if length(decoded_bits) < original_length
            decoded_bits = [decoded_bits; zeros(original_length - length(decoded_bits), 1)];
        end
    end
end

function llr_block = localPadLLR(llr_block, blockLength)
    if length(llr_block) < blockLength
        llr_block = [llr_block; zeros(blockLength - length(llr_block), 1)];
    end
end
