function  Frame_decoded = Demapping(N_mod,R,index_data_per_user,N_user);
[N_subcarrier,N_symbol] = size(R);
% M = zeros(N_subcarrier,N_symbol);
for iuser = 1:N_user
    M = R(index_data_per_user{iuser},:);
end
M = reshape(M,[],2);
switch N_mod
    case 1
        % 求解最大似然向量M
        mapping = [-1 0; 0 -1; 0 1;1 0];
        for m = 1:size(M,1)
            M(m,:) = mapping(find(dist(real(M(m,:)),mapping.')==min(dist(real(M(m,:)),mapping.'))),:);
        end
        % 解逆映射M^-1
        demap = [-1 0,0 0;0 -1,1 0;0 1,0 1;1 0,1 1];
        for m = 1:size(M,1)
            for i = 1:size(demap,1)
                if M(m,:) == demap(i,1:2)
                    M(m,:) = demap(i,3:4);
                end
            end
        end
        M = reshape(M,[],N_symbol);
Frame_decoded = M(:);
% for iuser = 1:N_user
%     Frame_decoded(index_data_per_user{iuser},:) = M;
% end
end