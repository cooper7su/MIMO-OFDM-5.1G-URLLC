function noise = NoiseGenerator(noise_var, N_noise, N_Rx)
% 生成复高斯白噪声，noise_var为每个复样点的总方差。

    if nargin < 3
        N_Rx = 1;
    end

    sigma = sqrt(max(noise_var, 0) / 2);
    noise = sigma .* (randn(1, N_noise, N_Rx) + 1i * randn(1, N_noise, N_Rx));
end
