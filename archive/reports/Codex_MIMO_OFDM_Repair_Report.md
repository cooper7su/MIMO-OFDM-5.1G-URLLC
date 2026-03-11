# SECTION 1: Code Modifications

File/Line: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/ApplyMIMOChannel.m:1`

Correction snippet:

```matlab
[Frame_channel, H_freq, channel_info] = ApplyMIMOChannel(Frame_transmit, cfg)
```

- 新增真实信道模块，发送端 `N_Tx` 时域波形先经过 `AWGN` 基准信道或 `TDL-A` 多径信道，再得到 `N_Rx` 接收波形。
- `TDL-A` 使用 3GPP 38.901 的 23 taps，按 `DS = 100 ns` 和 `f_s = 15.36 MHz` 生成整数采样延迟抽头。
- 同时输出每个 Tx-Rx 对的频域 `H_freq`，供接收端完美 CSI/MMSE 使用。

File/Line: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/STBCCoding.m:1`

Correction snippet:

```matlab
scale = 1 / sqrt(2);
Frame_STBC(:, idx, 1) = scale * s1;
Frame_STBC(:, idx, 2) = scale * s2;
Frame_STBC(:, idx + 1, 1) = -scale * conj(s2);
Frame_STBC(:, idx + 1, 2) = scale * conj(s1);
```

- 将 STBC 发射端限制到论文场景需要的 `1Tx/2Tx`。
- 对 `2Tx` Alamouti 编码增加 `1/sqrt(2)` 归一化，保持总发射符号能量不变。

File/Line: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/STBCDecoding.m:1`

Correction snippet:

```matlab
x1_num = x1_num + conj(h1) .* r1 + h2 .* conj(r2);
x2_num = x2_num + conj(h2) .* r1 - h1 .* conj(r2);
Frame_decoded(:, idx) = x1_num ./ max(signal_norm, eps);
effective_noise_var(:, idx:idx + 1) = repmat(noise_var ./ max(signal_norm, eps), 1, 2);
```

- 删除 `abs(H)` 的错误用法，改为复信道系数 Alamouti 合并。
- 输出 `effective_noise_var`，作为软判决和 MMSE 统计量输入。
- 支持 `1Tx` 和 `2Tx`，覆盖 `1x1`、`2x1`、`2x2` 验证场景。

File/Line: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/OFDMDemodulator.m:1`

Correction snippet:

```matlab
for iant = 1:N_Rx
    Frame_symbol = reshape(Frame_noise(1, :, iant), N_sym, N_symbol);
    Frame_noGI = Frame_symbol(N_GI + 1:end, :);
end
```

- 去掉旧代码里 `N_Rx==1` 时错误地把两路接收波形相加的逻辑。
- 改为对每根接收天线独立解 OFDM。

File/Line: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/NoiseGenerator.m:1`

Correction snippet:

```matlab
sigma = sqrt(max(noise_var, 0) / 2);
noise = sigma .* (randn(1, N_noise, N_Rx) + 1i * randn(1, N_noise, N_Rx));
```

- 噪声生成改为直接使用每个复样点总方差 `noise_var`。
- 配合新主脚本中的 `Eb/N0` 归一化公式，统一 CP、导频、码率和调制阶数影响。

File/Line: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/SymbolModulator.m:6`

Correction snippet:

```matlab
matrix_mapping = [-1 1];
```

- 将 BPSK 从 `±1/sqrt(2)` 修正为 `±1`，恢复单位符号能量。

File/Line: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/CalculateLLR.m:1`

Correction snippet:

```matlab
llr_matrix = [ ...
    2 * real(received_signal) ./ noise_var; ...
    2 * imag(received_signal) ./ noise_var];
```

- 软判决只保留论文需要的 `BPSK/QPSK`，输出顺序与 `SymbolDemodulator` 严格一致。
- 支持标量或逐符号噪声方差输入。

File/Line: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/ConvDecode_Soft.m:1`

Correction snippet:

```matlab
llr = -llr(:).';
decoded_bits = vitdec(llr, trellis, tb_depth, 'trunc', 'unquant');
```

- 启用软判决 Viterbi。
- 修正 `vitdec('unquant')` 的号向，避免卷积码 BER 反向跑到 `1.0`。

File/Line: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/FrameBitGenerator.m:1`

Correction snippet:

```matlab
function Frame_bit = FrameBitGenerator(..., N_bit_per_user)
```

- 新增显式 payload 长度接口，允许主脚本按编码后帧容量生成原始信息比特。

File/Line: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/SubcarrierAllocation.m:1`

Correction snippet:

```matlab
if length(current_bits) > total_bits_needed
    error('%s编码后长度%d超过单帧映射容量%d，禁止截断码字。', ...)
end
Frame_zero_padding{iuser} = [current_bits; zeros(total_bits_needed - length(current_bits), 1)];
```

- 去掉旧逻辑对 RS/LDPC 码流的截断。
- 现在只允许补零，不允许丢弃 parity bits。

File/Line: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/LDPC_Encode.m:1`

Correction snippet:

```matlab
num_full_blocks = floor(original_length / ldpc_k);
uncoded_bits = input_bits(num_to_code + 1:end);
coded_bits = [coded_blocks; uncoded_bits];
```

- 删除“凑不满一个块也强行编码再裁掉”的错误逻辑。
- 保持“整块 LDPC + 尾部直传”的论文描述。

File/Line: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/RS_Decode.m:45`

Correction snippet:

```matlab
warning('RS解码失败(块%d): %s，回退到系统位硬判决。', ...)
fallback_bits = codeword_bits(1:bits_per_msg);
```

- 去掉解码失败时写随机比特的做法，改为可追踪的系统位回退。

File/Line: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/debug_test.m:51`

Correction snippet:

```matlab
cfg.N_Tx = 2;
cfg.N_Rx = 2;
cfg.N_symbol = 12;
cfg.N_frame = 100;
cfg.N_subcarrier = 1024;
cfg.N_GI = 256;
cfg.f_carrier = 5.1e9;
cfg.channel_model = 'TDL-A';
cfg.code_rate = 1/3;
cfg.enable_soft_viterbi = true;
```

- 主入口重写为统一仿真驱动。
- 默认场景对齐论文推荐组合：`2x2 + TDL-A + QPSK + Conv(1/3)`。
- 同一入口里包含：主 BER 曲线、无噪声回环、AWGN 理论验证、RS/LDPC 全帧回环、评分保护验证。

File/Line: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/debug_test.m:316`

Correction snippet:

```matlab
noise_var = pilot_factor * cp_factor / (cfg.N_mod * cfg.R_code_eff * EbN0);
```

- `Eb/N0` 归一化显式纳入导频占比、CP 开销、调制阶数和有效码率。

File/Line: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/debug_test.m:323`

Correction snippet:

```matlab
if any(~isfinite(reqSNR))
    score = min(score, 60 - 10 * sum(~isfinite(reqSNR)));
end
```

- 修正评分逻辑，确保未达到 BER 门限时不可能再报 `100`。

# SECTION 2: Simulation Report

## Main scenario

- Scenario: `2x2_TDL-A_CONV_QPSK`
- Carrier frequency: `5.10 GHz`
- FFT / CP: `1024 / 256`
- OFDM symbols per frame: `12`
- Frames per run: `100`
- Channel: `TDL-A`, `DS = 100 ns`
- Coding: convolutional, rate `1/3`
- Modulation: `QPSK`

Measured BER:

| Eb/N0 (dB) | BER |
| --- | --- |
| 0 | 7.915e-02 |
| 2 | 1.936e-02 |
| 4 | 3.318e-03 |
| 6 | 1.248e-03 |
| 8 | 1.497e-04 |
| 10 | 6.510e-06 |
| 12 | 0.000e+00 |
| 14 | 0.000e+00 |
| 16 | 0.000e+00 |
| 18 | 0.000e+00 |
| 20 | 0.000e+00 |

Threshold summary:

- BER = `1e-2` at `3.17 dB`
- BER = `1e-3` at `6.45 dB`
- BER = `1e-4` at `8.69 dB`
- Combo score = `62.0`

Interpretation:

- 主场景 BER 曲线已恢复为随 `Eb/N0` 单调下降，不再出现旧版那种“随 SNR 升高反而逼近 1”的失真。
- 对于 `2x2 + TDL-A + Conv(1/3)`，`8~10 dB` 已进入很低 BER 区间，和论文里“低码率卷积码在 0-12 dB 区间表现最好”的结论一致。

Plots:

- Main BER plot: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/results/codex_validation/2x2_TDL-A_CONV_QPSK_main_ber.png`

## Validation suite

End-to-end no-noise checks:

- `2x1` OFDM/STBC roundtrip BER = `0`
- `2x2` OFDM/STBC roundtrip BER = `0`
- `RS` full-frame encode-map-decode BER = `0`
- `LDPC` full-frame encode-map-decode BER = `0`

AWGN theory checks:

- BPSK AWGN max absolute BER gap vs `Q(sqrt(2Eb/N0))`: `2.839e-4`
- QPSK AWGN max absolute BER gap vs `Q(sqrt(2Eb/N0))`: `3.586e-4`

Interpretation:

- BPSK/QPSK 调制、硬判决、`Eb/N0` 基准已经和理论曲线对齐，误差在 `1e-4` 量级。
- 说明修复后的符号能量和噪声方差归一化是正确的。

AWGN theory plot:

- `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/results/codex_validation/awgn_bpsk_qpsk_theory.png`

Score validation:

- Guard check passed = `true`
- 对一个始终达不到门限的虚拟 BER 曲线，评分不会再错误地返回 `100`

Component tests:

- `for_test_codedRS.m`: pass, no-noise BER = `0`
- `for_test_codedLDPC.m`: pass, no-noise BER = `0`

# SECTION 3: Remaining Issues / Warnings

- `comm.LDPCEncoder` / `comm.LDPCDecoder` 在 R2025a 会给出弃用警告，但当前实现仍兼容并通过组件测试。
- `TDL-A` 当前采用整数采样延迟抽头实现，便于与现有 OFDM/CP 框架直接对接；如果后续需要更严格贴合论文信道，可继续升级为分数时延或 `nrTDLChannel`。
- 当前接收端使用完美 CSI 驱动的等效 MMSE/STBC 统计量，没有进一步实现基于导频的 LS/LMMSE 信道估计；这比旧版正确得多，但仍属于“理想 CSI”验证链路。
- 主验证默认场景固定为论文推荐组合 `2x2 + TDL-A + QPSK + Conv(1/3)`；其他组合已通过 `debug_test.m` 的配置结构支持，但还没有把所有组合批量扫成完整论文图集。
