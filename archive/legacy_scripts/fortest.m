function Frame_DoSTBC = fortest(Frame_zero_padding, index_data_per_user, N_data, N_user,  N_mod,Frame_mod, N_subcarrier, N_symbol, N_Tx)

Frame_mod = zeros(N_subcarrier, N_symbol);
N_subcarrier_per_user = N_data / N_user;
for iuser = 1:N_user
    for isymbol = 1:N_symbol
        L_symbol = N_subcarrier_per_user* N_mod;
        index_symbol = (isymbol-1)*L_symbol+1 : isymbol*L_symbol;
        Symbol = Frame_zero_padding{iuser}(index_symbol);
        Symbol_premod = reshape(Symbol, N_mod, N_subcarrier_per_user);
        data_raw((iuser-1)*N_subcarrier_per_user+(1:N_subcarrier_per_user),(isymbol-1)*N_mod+1:isymbol*N_mod) = Symbol_premod.';
    end
end
 Symbol_Dimod = Differential_Mapping(data_raw);



for iuser = 1:N_user
    for isymbol = 1:N_symbol
        L_symbol = N_subcarrier_per_user* N_mod;
        index_symbol = (isymbol-1)*L_symbol+1 : isymbol*L_symbol;
        Symbol = Frame_zero_padding{iuser}(index_symbol);
        Symbol_premod = reshape(Symbol, N_mod, N_subcarrier_per_user);
        data_raw() = Symbol_premod.';

        Symbol_Dimod = Differential_Mapping(Symbol_premod);
        Symbol_mod = SymbolModulator(Symbol_Dimod);
        Frame_mod(index_data_per_user{iuser}, isymbol) = Symbol_mod.';
    end
end


Frame_DoSTBC = zeros(N_subcarrier, N_symbol, N_Tx);
if (mod(N_symbol,N_Tx))
    error('空时编码器输入符号不匹配,子程序st_coding出错');
else
    for ispace = 1:N_symbol/N_Tx
        if N_Tx == 2
            X1=Frame_mod(:,(ispace-1)*N_Tx+1);%取第一列，即第一个OFDM符号
            X2=Frame_mod(:,(ispace-1)*N_Tx+2);%取第二列，即第二个OFDM符号
            Symbol_STBC = [X1 X2;-conj(X2) conj(X1)];%alamouti编码
        elseif N_Tx == 4
            X1=Frame_mod(:,(ispace-1)*N_Tx+1);%取第一列，即第一个OFDM符号
            X2=Frame_mod(:,(ispace-1)*N_Tx+2);%取第二列，即第二个OFDM符号
            X3=Frame_mod(:,(ispace-1)*N_Tx+3);%取第一列，即第一个OFDM符号
            X4=Frame_mod(:,(ispace-1)*N_Tx+4);%取第二列，即第二个OFDM符号
            Symbol_STBC = [ X1 X2 X3  X4;...
                            -X2 X1 -X4 X3;...
                            -X3 X4 X1 -X2;...
                            -X4 -X3 X2 X1;...
                            conj(X1) conj(X2) conj(X3) conj(X4);...
                            -conj(X2) conj(X1) -conj(X4) conj(X3);...
                            -conj(X3) conj(X4) conj(X1) -conj(X2);...
                            -conj(X4) -conj(X3) conj(X2) conj(X1)];
        end
        for iant = 1:N_Tx
            Symbol_STBC_per_ant = reshape(Symbol_STBC(:,iant), N_subcarrier, N_Tx);
            Frame_DoSTBC(:, (ispace-1)*N_Tx+1:ispace*N_Tx, iant) = Symbol_STBC_per_ant;
        end
    end
end
