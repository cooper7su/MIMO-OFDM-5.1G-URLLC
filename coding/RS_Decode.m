 function decoded_bits = RS_Decode(received_bits, n, k, m, orig_length)
   
    % 计算块参数
    bits_per_symbol = m;
    symbols_per_codeword = n;
    symbols_per_msg = k;
    bits_per_codeword = n * bits_per_symbol;
    bits_per_msg = k * bits_per_symbol;
    
    % 预分配输出
    decoded_bits = zeros(orig_length, 1);
    write_pos = 1;
    
    % 计算需要的完整块数
    num_full_blocks = floor(length(received_bits) / bits_per_codeword);
    
    for block_idx = 1:num_full_blocks
        % 提取当前码字
        start_bit = (block_idx-1)*bits_per_codeword + 1;
        end_bit = block_idx*bits_per_codeword;
        codeword_bits = received_bits(start_bit:end_bit);
        
        % 转换为符号
        codeword_symbols = bi2de(reshape(codeword_bits, bits_per_symbol, [])', 'left-msb')';
        
        % RS解码
        try
            % 创建GF域对象
            gf_obj = gf(codeword_symbols, m);
            
            % 解码
            decoded_msg = rsdec(gf_obj, n, k);
            
            % 转换回比特
            decoded_block = de2bi(double(decoded_msg.x), bits_per_symbol, 'left-msb')';
            decoded_block = decoded_block(:);
            
            % 写入有效数据
            read_length = min(length(decoded_block), orig_length-write_pos+1);
            if read_length > 0
                decoded_bits(write_pos:write_pos+read_length-1) = ...
                    decoded_block(1:read_length);
                write_pos = write_pos + read_length;
            end
        catch ME
            warning('RS解码失败(块%d): %s，回退到系统位硬判决。', block_idx, ME.message);
            fallback_bits = codeword_bits(1:bits_per_msg);
            read_length = min(length(fallback_bits), orig_length-write_pos+1);
            if read_length > 0
                decoded_bits(write_pos:write_pos+read_length-1) = fallback_bits(1:read_length);
                write_pos = write_pos + read_length;
            end
        end
    end
end
