function [index_data_per_user, Frame_zero_padding] = SubcarrierAllocation( ...
    Frame_bit_coded, index_data, N_data, N_user, N_symbol, N_mod, type_alloc, ~, Coded_method)
% 将每用户编码比特映射到固定帧容量；允许补零，但禁止截断码字。

    if nargin < 9
        Coded_method = 'NULL';
    end

    Frame_zero_padding = cell(1, N_user);
    index_data_per_user = cell(1, N_user);
    N_subcarrier_per_user = N_data / N_user;
    total_bits_needed = N_mod * N_subcarrier_per_user * N_symbol;

    for iuser = 1:N_user
        if type_alloc == "neighbour"
            idx_start = (iuser - 1) * N_subcarrier_per_user + 1;
            idx_end = iuser * N_subcarrier_per_user;
            index_data_per_user{iuser} = index_data(idx_start:idx_end).';
        else
            index_data_per_user{iuser} = index_data(iuser:N_user:end).';
        end

        current_bits = localGetEntry(Frame_bit_coded, iuser).data(:);
        if length(current_bits) > total_bits_needed
            error('%s编码后长度%d超过单帧映射容量%d，禁止截断码字。', ...
                Coded_method, length(current_bits), total_bits_needed);
        end

        Frame_zero_padding{iuser} = [current_bits; zeros(total_bits_needed - length(current_bits), 1)];
    end
end

function entry = localGetEntry(frame_bits, idx)
    if iscell(frame_bits)
        entry = frame_bits{idx};
    else
        entry = frame_bits(idx);
    end
end
