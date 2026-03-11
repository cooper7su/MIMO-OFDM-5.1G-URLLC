function stbc = GetSTBCConfig(N_Tx)
%GETSTBCCONFIG Resolve the virtual STBC structure for the requested Tx count.

    stbc = struct();
    stbc.num_tx = N_Tx;

    switch N_Tx
        case 1
            stbc.scheme = 'single_stream';
            stbc.num_streams = 1;
            stbc.group_weights = 1;

        case 2
            stbc.scheme = 'alamouti_2tx';
            stbc.num_streams = 2;
            stbc.group_weights = eye(2);

        case 4
            stbc.scheme = 'replicated_alamouti_4tx';
            stbc.num_streams = 2;
            groupScale = 1 / sqrt(2);
            stbc.group_weights = [ ...
                groupScale, 0; ...
                0, groupScale; ...
                groupScale, 0; ...
                0, groupScale];

        otherwise
            error('当前框架仅支持1Tx、2Tx或4Tx配置。');
    end

    stbc.group_map = stbc.group_weights ~= 0;
end
