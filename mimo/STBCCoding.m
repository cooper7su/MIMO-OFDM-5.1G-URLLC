function Frame_STBC = STBCCoding(Frame_mod, varargin)
%STBCCODING Apply the configured single-stream or Alamouti-style Tx mapping.

    if nargin == 2 && isstruct(varargin{1})
        cfg = varargin{1};
        N_subcarrier = cfg.N_subcarrier;
        N_symbol = cfg.N_symbol;
        N_Tx = cfg.N_Tx;
        stbc = cfg.stbc;
    elseif nargin == 4
        N_subcarrier = varargin{1};
        N_symbol = varargin{2};
        N_Tx = varargin{3};
        stbc = GetSTBCConfig(N_Tx);
    else
        error('STBCCoding输入参数不正确。');
    end

    if stbc.num_streams == 1
        Frame_STBC = reshape(Frame_mod, N_subcarrier, N_symbol, N_Tx);
        return;
    end

    if mod(N_symbol, 2) ~= 0
        error('Alamouti编码要求N_symbol为偶数');
    end

    virtualFrame = complex(zeros(N_subcarrier, N_symbol, stbc.num_streams));
    scale = 1 / sqrt(2);
    for ispace = 1:(N_symbol / 2)
        idx = 2 * ispace - 1;
        s1 = Frame_mod(:, idx);
        s2 = Frame_mod(:, idx + 1);
        virtualFrame(:, idx, 1) = scale * s1;
        virtualFrame(:, idx, 2) = scale * s2;
        virtualFrame(:, idx + 1, 1) = -scale * conj(s2);
        virtualFrame(:, idx + 1, 2) = scale * conj(s1);
    end

    Frame_STBC = complex(zeros(N_subcarrier, N_symbol, N_Tx));
    for itx = 1:N_Tx
        for istream = 1:stbc.num_streams
            weight = stbc.group_weights(itx, istream);
            if weight ~= 0
                Frame_STBC(:, :, itx) = Frame_STBC(:, :, itx) + weight .* virtualFrame(:, :, istream);
            end
        end
    end
end
