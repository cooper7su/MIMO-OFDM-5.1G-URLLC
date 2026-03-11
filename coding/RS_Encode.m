 function coded_bits = RS_Encode(input_bits, n, k, m)
   
    % 确保输入是列向量
    input_bits = input_bits(:);   
    % 计算块参数
    bits_per_symbol = m;
    bits_per_block = k * bits_per_symbol;
    num_blocks = ceil(length(input_bits) / bits_per_block);
    % 预分配输出
    coded_bits = zeros(num_blocks * n * bits_per_symbol, 1);
    % 生成多项式（预计算提升性能）
    gen_poly = rsgenpoly(n, k, [], 0);
    
    for i = 1:num_blocks
        % 获取当前数据块
        start_idx = (i-1)*bits_per_block + 1;
        end_idx = min(i*bits_per_block, length(input_bits));
        block = input_bits(start_idx:end_idx);
        
        % 填充处理（保持符号对齐）
        if length(block) < bits_per_block
            block = [block; zeros(bits_per_block-length(block), 1)];
        end
        
        % 转换为符号矩阵
        symbol_matrix = reshape(block, bits_per_symbol, [])';
        msg_syms = bi2de(symbol_matrix, 'left-msb');
        
        % RS编码（严格维度控制）
        try
            % 确保msg_syms是行向量
            if iscolumn(msg_syms)
                msg_syms = msg_syms';
            end
            
            % GF域转换与编码
            gf_msg = gf(msg_syms, m);
            code_syms = rsenc(gf_msg, n, k, gen_poly);
            
            % 转换回比特
            coded_block = de2bi(double(code_syms.x), bits_per_symbol, 'left-msb')';
            coded_bits((i-1)*n*bits_per_symbol+1 : i*n*bits_per_symbol) = coded_block(:);
        catch ME
            error('RS编码失败(块%d): %s', i, ME.message);
        end
    end
end