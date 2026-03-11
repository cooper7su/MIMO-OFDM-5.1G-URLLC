function Frame_mod = Modulator(Frame_zero_padding, index_data_per_user, ...
    N_data, N_user, N_symbol, N_mod, N_subcarrier)
%MODULATOR Map padded user bits onto the active data subcarriers.

    Frame_mod = zeros(N_subcarrier, N_symbol);
    N_subcarrier_per_user = N_data / N_user;

    for iuser = 1:N_user
        for isymbol = 1:N_symbol
            bits_per_symbol = N_subcarrier_per_user * N_mod;
            index_symbol = (isymbol - 1) * bits_per_symbol + 1 : isymbol * bits_per_symbol;
            symbol_bits = Frame_zero_padding{iuser}(index_symbol);
            symbol_matrix = reshape(symbol_bits, N_mod, N_subcarrier_per_user);
            symbol_mod = SymbolModulator(symbol_matrix);
            Frame_mod(index_data_per_user{iuser}, isymbol) = symbol_mod.';
        end
    end
end
