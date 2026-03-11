# MIMO-OFDM 5.1G URLLC MATLAB Simulation Framework

面向 5.1G URLLC 的研究级 MATLAB MIMO-OFDM 链路仿真平台，覆盖从单场景验证、全矩阵批量扫参，到 publication-ready 数据集、图表和审计报告的完整实验链路。当前仓库适合：

- 研究复现与方法对比
- 课程设计 / 毕业设计 / 答辩展示
- 论文图表导出与结果归档
- GitHub 作品集与工程展示

**GitHub 仓库简介**

`Research-grade MATLAB MIMO-OFDM URLLC simulation framework with static/dynamic channels, pilot-aided CSI estimation, finite-blocklength evaluation, and publication-ready datasets.`

**当前完成状态**

- Phase 1：工程重构与目录整理
- Phase 2：批量实验基础设施与 `Rician` 信道接入
- Phase 3：导频辅助 LS 信道估计、可选 MMSE 等化、URLLC 指标与多指标绘图
- Phase 4：有限块长/短包评估、packet-length sweep、可靠性指标与 publication dataset
- Phase 5：动态多径信道、统计先验 MMSE / Kalman / Bayesian 估计链路、统一 Phase 5 publication 数据集与审计报告

**仓库亮点**

- 完整链路：信息比特、编码、调制、OFDM、MIMO/STBC、信道、估计、等化、译码、统计全覆盖
- 多维实验：支持 `MIMO x Channel x Coding x Modulation x PacketLength` 全矩阵 sweep
- 结果可复现：统一 `cfg` 配置、固定随机种子、保留 Phase 2–5 结果与回归基线
- 面向展示：仓库内已包含 publication dataset、批量报告、审计报告和图表输出
- 向后兼容：保留 `debug_test.m`、`for_test_codedRS.m`、`for_test_codedLDPC.m`

**从哪里开始**

- 想快速运行一个场景：看 `main_run.m`
- 想批量生成整组实验：看 `main_batch.m`
- 想看核心执行链路：看 `main/run_single_case.m`
- 想看信道、估计与接收机：看 `channels/`、`mimo/`、`ofdm/`
- 想看最终数据集与图表：看 `results/phase5_publication/`
- 想看完整实验结果：看 `results/batch_sweeps/`

**公开仓库导航**

- 如果你是第一次看这个仓库，建议按 `README -> main_run.m -> main_batch.m -> results/phase5_publication/ -> results/batch_sweeps/` 的顺序浏览。
- 如果你只关心可展示成果，优先看 `results/phase5_publication/phase5_publication_dataset.mat`、`phase5_progress_report.md`、`phase5_audit_report.md` 和 `plots/`。
- 如果你只关心代码结构，优先看 `configs/`、`main/`、`channels/`、`mimo/`、`ofdm/`、`coding/`、`validation/`。
- 本仓库有意保留 `results/` 大量数据和图，以保证可复现与可审计，因此仓库体积较大。

当前维护的主链路支持：

- MIMO：`1x1`、`2x1`、`2x2`、`2x4`、`4x4`
- 调制：`BPSK`、`QPSK`
- 编码：`Conv`、`RS`、`LDPC`
- 信道：`AWGN`、静态/动态 `TDL-A/B/C/D`、静态 `Rician`、动态 `Rayleigh/Rician`
- 接收机：`ideal CSI`、`pilot-based LS/MMSE`、`Kalman`、`Bayesian`
- packet length：`short`、`medium`、`long`，也支持显式 `N_bits_per_packet` / `N_symbols_per_packet`
- 指标：`BER`、`BLER`、`reliability`、`effective throughput`、`latency proxy`、`NMSE`、`BLER confidence interval`、`reliability tail probability`

## 目录结构

```text
MIMO_OFDM_simulation-main/
├── main_run.m                 % 单场景入口
├── main_batch.m               % 批量 sweep 入口
├── debug_test.m               % 旧入口兼容包装
├── for_test_codedRS.m         % 旧 RS 测试入口兼容包装
├── for_test_codedLDPC.m       % 旧 LDPC 测试入口兼容包装
├── setup_project_paths.m      % 注册源代码路径
├── configs/                   % 默认配置、覆盖配置、派生参数
├── main/                      % 单场景执行流程、发射链、接收链、统计
├── channels/                  % 静态/动态信道、导频估计与动态跟踪
├── mimo/                      % STBC 编解码
├── ofdm/                      % OFDM、子载波和导频网格
├── coding/                    % Conv / RS / LDPC 编解码
├── modulation/                % 星座映射、LLR
├── utils/                     % 通用工具、URLLC 指标、publication 数据集与审计
├── plotting/                  % 单场景图、summary 图、Phase 5 publication 图
├── validation/                % 无噪声回环、理论对齐、组件 sanity check
├── data/ldpc/                 % LDPC 校验矩阵
├── results/                   % 单场景和批量结果
└── archive/                   % 遗留脚本、旧图、历史材料
```

### 目录导览

- `main_run.m`：最清晰的单场景入口，适合首次运行、调试和理解主流程。
- `main_batch.m`：批量 sweep 入口，适合论文图表、基线对比和大规模结果归档。
- `configs/`：统一参数入口，所有 MIMO、信道、估计、有限块长和统计参数都从这里派生。
- `main/`：真正的发射链、信道调用、接收链和统计主流程。
- `channels/`：静态与动态信道、LS/MMSE/Kalman/Bayesian 估计逻辑的核心位置。
- `validation/`：无噪声回环、AWGN 理论对齐、RS/LDPC sanity check 和 Phase 5 smoke validation。
- `results/phase5_publication/`：最适合公开展示的成果目录，包含统一数据集、报告和 publication 图。
- `results/batch_sweeps/`：每一轮 sweep 的原始结果目录，适合回溯具体场景和做二次分析。

## Phase 5 核心流程

### 1. 发射端

- 生成每帧信息比特
- 进行 `Conv / RS / LDPC` 编码
- 完成子载波映射
- 执行 `Alamouti STBC`
- 写入导频

### 2. 信道

- `AWGN`
- 静态 `TDL-A/B/C/D`
- 启用 `enable_dynamic_channel / use_fractional_delay / velocity_mps` 后的动态 `TDL-A/B/C/D`
- 静态 `Rician`，默认 `K_factor = 10`
- 动态 `Dynamic-Rayleigh`
- 动态 `Dynamic-Rician`

### 3. 接收端

- OFDM 解调
- 根据信号模式选择：
  - `ideal CSI`
  - `pilot-based estimated CSI`
- 当前估计方法：`LS`、`MMSE`、`Kalman`、`Bayesian`
- 当前等化选项：`ZF` 或 `MMSE`
- STBC 合并与译码

### 4. 输出指标

- `BER`
- `BLER`
- `effective throughput`
- `nominal throughput`
- `latency proxy`
- `channel NMSE`
- `BLER confidence interval`
- `reliability target confidence`
- `reliability tail probability`
- 可选 `estimated vs ideal` 对比

## 导频与信道估计

### 默认导频参数

- 导频子载波：由 `cfg.index_pilot_base` 派生
- 默认导频幅度：`cfg.pilot_amplitude = 1`
- 默认频域插值：`cfg.pilot_interpolation = 'linear'`

### 估计模式说明

- 当 `cfg.enable_pilot_estimation = false` 时：
  - 走 Phase 2 的 `ideal CSI` 主链路
  - 用于保持旧结果和批量回归不变

- 当 `cfg.enable_pilot_estimation = true` 时：
  - 发射端切换到适合 `2Tx` 分离估计的正交时间导频模式
  - 接收端使用 `LS` 从导频估计每条 `Tx-Rx` 频域信道
  - `cfg.equalizer_type` 可选 `ZF` 或 `MMSE`

- 当 `cfg.N_Tx = 4` 时：
  - 使用两组虚拟 `Alamouti` 流映射到四根发射天线
  - 当前分组为 `[1 3]` 和 `[2 4]`
  - 该实现面向工程扩展和批量实验，不等价于完整 `4Tx` 正交 STBC 标准设计

- 当 `cfg.compare_csi_with_ideal = true` 时：
  - 单次仿真会同时输出 `estimated` 与 `ideal` 两条曲线
  - 两者复用同一帧和同一信道实现公平对比

## URLLC 指标定义

- `BER`
  - 误比特率，按所有信息比特统计

- `BLER`
  - 每帧块错误率
  - 当前实现中，对每个用户每帧只要存在至少一个误比特，即记为一个 block error

- `latency proxy`
  - 采用单帧持续时间
  - 定义为：
  - `frame_duration = N_symbol * (N_subcarrier + N_GI) / f_sample`

- `nominal throughput`
  - `payload_bits_per_frame / frame_duration`

- `effective throughput`
  - `payload_bits_per_frame * (1 - BLER) / frame_duration`

- `reliability target confidence`
  - 基于 `blockErrors / totalBlocks` 的 Beta-Binomial 后验
  - 表示“真实 BLER 小于目标阈值”的后验置信度

- `BLER confidence interval`
  - 默认 `95%` Jeffreys 区间
  - 用于有限块长 Monte Carlo 结果的不确定性表达

### 短包评估

Phase 4/5 已支持有限块长/短包评估。最直接的使用方式是通过覆盖：

- `packet_length_mode`
- `N_symbol`
- `N_bits_per_packet`
- `N_frame`
- `EbN0s_dB`

来构造更短的 packet，并沿用同一套 `BER / BLER / reliability / throughput / latency` 统计。

默认 packet profile：

- `short`：`4` OFDM symbols
- `medium`：`8` OFDM symbols
- `long`：`12` OFDM symbols

如果同时提供 `N_symbols_per_packet` 或 `N_bits_per_packet`，显式配置优先。

## 如何运行

### 1. 单场景：Phase 2 兼容 ideal-CSI

```matlab
main_run
```

默认场景：

- `2x2`
- `TDL-A`
- `QPSK`
- `Conv(1/3)`
- `ideal CSI`
- `ZF`

### 2. 单场景：pilot-based estimated CSI

```matlab
main_run( ...
    'enable_pilot_estimation', true, ...
    'equalizer_type', 'MMSE');
```

### 3. 单场景：estimated vs ideal 对比

```matlab
main_run( ...
    'enable_pilot_estimation', true, ...
    'compare_csi_with_ideal', true, ...
    'equalizer_type', 'MMSE', ...
    'scenario_name', 'pilot_compare_demo');
```

### 4. 单场景：短包评估

```matlab
main_run( ...
    'packet_length_mode', 'short', ...
    'N_bits_per_packet', 512, ...
    'N_frame', 20, ...
    'enable_pilot_estimation', true, ...
    'scenario_name', 'short_packet_demo');
```

### 5. 批量 sweep：Phase 2 兼容 ideal-CSI

```matlab
main_batch
```

默认 sweep 维度：

- MIMO：`{2x1, 2x2}`
- 调制：`{BPSK, QPSK}`
- 编码：`{Conv, RS, LDPC}`
- 信道：`{AWGN, TDL-A}`

如需完整扩展矩阵，可覆盖：

```matlab
opts = struct( ...
    'mimo_modes', [1 1; 2 1; 2 2; 2 4; 4 4], ...
    'channel_modes', {'AWGN','TDL-A','TDL-B','TDL-C','TDL-D','Rician'}, ...
    'packet_length_modes', {'long','medium','short'});
main_batch(opts);
```

### 6. 批量 sweep：含 Rician 的 estimated-CSI

```matlab
opts = struct( ...
    'channel_modes', {'AWGN','TDL-A','TDL-B','TDL-C','TDL-D','Rician'}, ...
    'mimo_modes', [1 1; 2 1; 2 2; 2 4; 4 4], ...
    'packet_length_modes', {'long','medium','short'}, ...
    'enable_pilot_estimation', true, ...
    'equalizer_type', 'MMSE', ...
    'rician_K_factor', 10, ...
    'sweep_name', 'phase5_estimation_batch');
main_batch(opts);
```

### 7. 批量 sweep：Phase 5 动态信道 + Kalman / MMSE

```matlab
opts = struct( ...
    'mimo_modes', [1 1; 2 1; 2 2; 2 4; 4 4], ...
    'channel_modes', {'Dynamic-Rayleigh','Dynamic-Rician'}, ...
    'packet_length_modes', {'long','medium','short'}, ...
    'enable_dynamic_channel', true, ...
    'use_fractional_delay', true, ...
    'velocity_mps', 30, ...
    'enable_pilot_estimation', true, ...
    'channel_estimation_method', 'KALMAN', ...
    'compare_csi_with_ideal', true, ...
    'equalizer_type', 'MMSE', ...
    'sweep_name', 'phase5_dynamic_extension_v2', ...
    'report_filename', 'phase5_progress_report.md', ...
    'publication_dataset_filename', 'phase5_publication_dataset.mat');
main_batch(opts);
```

### 8. Phase 5 聚合、审计与 publication 图

```matlab
phase5_finalize
```

该入口会：

- 聚合 `phase4_full_matrix_smoke` 与 `phase5_dynamic_extension_v2`
- 生成统一数据集 `results/phase5_publication/phase5_publication_dataset.mat`
- 生成统一 publication 图 `results/phase5_publication/plots/`
- 生成进展报告 `results/phase5_publication/phase5_progress_report.md`
- 生成审计报告 `results/phase5_publication/phase5_audit_report.md`

## 输出结果

### 单场景输出

```text
results/<custom_dir>/
├── main_run_results.mat
├── <scenario>_BER.png
├── <scenario>_BLER.png
├── <scenario>_THROUGHPUT.png
└── <scenario>_SUMMARY.png
```

### 批量输出

```text
results/batch_sweeps/<sweep_name>/
├── batch_summary.mat
├── phase5_progress_report.md
├── phase5_publication_dataset.mat
└── scenarios/
    ├── AWGN/
    │   └── <scenario>/
    │       ├── mat/
    │       └── plots/
    ├── TDL-A/
    ├── TDL-B/
    ├── TDL-C/
    ├── TDL-D/
    └── RICIAN/
```

`main_batch` 在 sweep 完成后会自动生成 `phase5_progress_report.md` 和 `phase5_publication_dataset.mat`，其中包含：

- sweep 成功/失败统计
- MAT/PNG 文件计数
- 每个场景的 `packet length / BER / BLER / reliability / throughput / latency / NMSE / tail probability`
- `BER / BLER / THROUGHPUT / SUMMARY` 图路径
- publication-ready 的聚合场景行数据

### Phase 5 统一输出

```text
results/phase5_publication/
├── phase5_publication_dataset.mat
├── phase5_progress_report.md
├── phase5_audit_report.md
├── phase5_audit_summary.mat
├── phase5_bundle.mat
└── plots/
    ├── phase5_global_packet_summary.png/.pdf
    ├── phase5_dynamic_tradeoff.png/.pdf
    ├── 2x2_DYNAMIC-RAYLEIGH_CONV_QPSK_PHASE5_PACKET_TRADEOFF.png/.pdf
    ├── 2x2_DYNAMIC-RAYLEIGH_CONV_QPSK_PHASE5_CSI_COMPARISON.png/.pdf
    └── ...
```

统一 `phase5_publication_dataset.mat` 包含：

- `ESTIMATED / IDEAL` 双 CSI 模式
- `LONG / MEDIUM / SHORT` 三种 packet length
- `BER / BLER / throughput / latency / NMSE`
- `BLER confidence interval`
- `reliability target confidence`
- `reliability tail probability`
- 导频与等化元数据：`pilot_amplitude / pilot_interpolation / equalizer_type / channel_estimation_method`
- 动态信道元数据：`enable_dynamic_channel / use_fractional_delay / velocity_mps / max_doppler_hz / K_factor`

### 命名规则

- `<MIMO>_<Channel>_<Coding>_<Modulation>_BER.png`
- `<MIMO>_<Channel>_<Coding>_<Modulation>_BLER.png`
- `<MIMO>_<Channel>_<Coding>_<Modulation>_THROUGHPUT.png`
- `<MIMO>_<Channel>_<Coding>_<Modulation>_SUMMARY.png`
- `<MIMO>_<Channel>_<Coding>_<Modulation>.mat`

## 验证建议

### 最小验证

```matlab
main_run('N_frame', 1, 'EbN0s_dB', [0 4])
for_test_codedRS
for_test_codedLDPC
```

### Phase 5 动态估计链路验证

```matlab
main_run( ...
    'N_frame', 1, ...
    'EbN0s_dB', [0 4], ...
    'channel_model', 'Dynamic-Rician', ...
    'enable_dynamic_channel', true, ...
    'use_fractional_delay', true, ...
    'velocity_mps', 25, ...
    'enable_pilot_estimation', true, ...
    'channel_estimation_method', 'KALMAN', ...
    'compare_csi_with_ideal', true, ...
    'equalizer_type', 'MMSE');
```

### 批量烟雾测试

```matlab
opts = struct( ...
    'channel_modes', {'AWGN','TDL-A','TDL-B','TDL-C','TDL-D','Rician','Dynamic-Rayleigh','Dynamic-Rician'}, ...
    'mimo_modes', [1 1; 2 1; 2 2; 2 4; 4 4], ...
    'packet_length_modes', {'long','medium','short'}, ...
    'enable_pilot_estimation', true, ...
    'channel_estimation_method', 'MMSE', ...
    'equalizer_type', 'MMSE', ...
    'N_frame', 1, ...
    'EbN0s_dB', [0 4], ...
    'sweep_name', 'phase5_smoke', ...
    'report_filename', 'phase5_progress_report.md', ...
    'publication_dataset_filename', 'phase5_publication_dataset.mat');
main_batch(opts);
```

## 当前限制

- `LS` 估计当前基于导频观测和线性时频插值，主要用于工程验证。
- `MMSE` 估计使用统计先验相关性近似，不是严格的标准最优 Wiener 解。
- `Kalman / Bayesian` 跟踪当前是低维工程化实现，重点是支持动态信道比较和 NMSE/URLLC 指标链路。
- 有限块长评估当前采用 packetized Monte Carlo + padding/shortening 的工程化方法，尚未引入严格的 normal approximation 或 saddlepoint 分析。
- `Dynamic-Rayleigh / Dynamic-Rician / 动态 TDL-A/B/C/D` 已支持分数时延和 Doppler 参数，但仍是链路级可控模型，不等价于完整 3GPP 时变信道对象。
- `4Tx` 当前采用分组复制 `Alamouti` 虚拟流方案，以兼容现有 Phase 5 接收链；这是一种工程化扩展，不是完整 `4Tx` 正交 STBC 基准。
- `LDPC` 当前仍依赖 `comm.LDPCEncoder` / `comm.LDPCDecoder`，MATLAB R2025a 已提示未来弃用。

## Phase 5 之后的扩展方向

- 更严格的 pilot-based MMSE / Wiener / Bayesian channel estimation
- 更真实的时变、多普勒、分数时延与 mobility-aware 标准信道
- 有限块长 rare-event / tail probability 分析
- 自动生成论文图表、表格和投稿版摘要
- reliability / latency / throughput 联合评价与 Pareto 曲线
