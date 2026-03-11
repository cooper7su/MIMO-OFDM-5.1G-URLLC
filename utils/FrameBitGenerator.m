function Frame_bit = FrameBitGenerator(N_data, N_user, N_mod, N_symbol, N_bit_per_user)
% 生成每用户的原始信息比特。
% 兼容旧接口，也支持显式指定每用户信息比特长度。

    if nargin >= 5 && ~isempty(N_bit_per_user)
        if isscalar(N_bit_per_user)
            N_bit_per_user = repmat(N_bit_per_user, 1, N_user);
        end
        if numel(N_bit_per_user) ~= N_user
            error('N_bit_per_user长度必须等于N_user');
        end
    else
        N_bit_per_symbol = N_mod * N_data;
        N_bit_per_user_per_symbol = repmat(N_bit_per_symbol / N_user, 1, N_user);
        N_bit_per_user = N_bit_per_user_per_symbol * N_symbol;
    end

    Frame_bit = repmat(struct('data', [], 'num', 0), 1, N_user);
    for iuser = 1:N_user
        Frame_bit(iuser).data = rand(N_bit_per_user(iuser), 1) > 0.5;
        Frame_bit(iuser).num = N_bit_per_user(iuser);
    end
end
