# Phase 5 Progress Report

- Generated: 2026-03-11 14:46:22
- Publication dataset: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/results/phase5_publication/phase5_publication_dataset.mat`
- Audit report: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/results/phase5_publication/phase5_audit_report.md`

## Coverage

- Batch roots: `2`
- Scenario rows: `1440`
- MIMO configurations: `1x1, 2x1, 2x2, 2x4, 4x4`
- Channels: `AWGN, DYNAMIC-RAYLEIGH, DYNAMIC-RICIAN, RICIAN, TDL-A, TDL-B, TDL-C, TDL-D`
- Coding modes: `CONV, LDPC, RS`
- Modulations: `BPSK, QPSK`
- Packet lengths: `LONG, MEDIUM, SHORT`
- CSI modes: `ESTIMATED, IDEAL`
- Estimators: `IDEAL, KALMAN, LS`

## Detailed Scenario Tables

- `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/results/batch_sweeps/phase4_full_matrix_smoke` -> `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/results/batch_sweeps/phase4_full_matrix_smoke/phase4_progress_report.md`
- `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/results/batch_sweeps/phase5_dynamic_extension_v2` -> `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/results/batch_sweeps/phase5_dynamic_extension_v2/phase5_progress_report.md`

## Batch Checks

| Sweep | Scenarios | Success | Failed | Rows | PNG | Missing Figures | Metric Issues | Passed |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| phase4_full_matrix_smoke | 540 | 540 | 0 | 1080 | 2160 | 0 | 0 | 1 |
| phase5_dynamic_extension_v2 | 180 | 180 | 0 | 360 | 720 | 0 | 0 | 1 |

## Regression

| Reference | Shared Scenarios | maxDiff | Passed |
| --- | ---: | ---: | --- |
| Phase 3 overlap | 180 | 0 | 1 |
| Phase 2 overlap | 36 | 0 | 1 |

## Metric Summary By Channel

| Channel | CSI | Rows | Median BER@max | Median BLER@max | Median TP@max (bps) | Median Latency (s) | Median NMSE@max |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| AWGN | ESTIMATED | 90 | 0.000e+00 | 0.000e+00 | 2215384.615 | 6.933e-04 | 2.084e+00 |
| AWGN | IDEAL | 90 | 0.000e+00 | 0.000e+00 | 2561538.462 | 6.933e-04 | NaN |
| DYNAMIC-RAYLEIGH | ESTIMATED | 90 | 3.046e-02 | 1.000e+00 | 0.000 | 6.933e-04 | 4.475e-01 |
| DYNAMIC-RAYLEIGH | IDEAL | 90 | 2.102e-03 | 1.000e+00 | 0.000 | 6.933e-04 | NaN |
| DYNAMIC-RICIAN | ESTIMATED | 90 | 2.124e-02 | 1.000e+00 | 0.000 | 6.933e-04 | 4.811e-01 |
| DYNAMIC-RICIAN | IDEAL | 90 | 2.105e-03 | 1.000e+00 | 0.000 | 6.933e-04 | NaN |
| RICIAN | ESTIMATED | 90 | 1.176e-04 | 1.000e+00 | 0.000 | 6.933e-04 | 2.444e+00 |
| RICIAN | IDEAL | 90 | 0.000e+00 | 0.000e+00 | 2215384.615 | 6.933e-04 | NaN |
| TDL-A | ESTIMATED | 90 | 1.261e-03 | 1.000e+00 | 0.000 | 6.933e-04 | 4.023e+00 |
| TDL-A | IDEAL | 90 | 5.618e-04 | 1.000e+00 | 0.000 | 6.933e-04 | NaN |
| TDL-B | ESTIMATED | 90 | 3.223e-03 | 1.000e+00 | 0.000 | 6.933e-04 | 3.550e+00 |
| TDL-B | IDEAL | 90 | 1.545e-03 | 1.000e+00 | 0.000 | 6.933e-04 | NaN |
| TDL-C | ESTIMATED | 90 | 2.429e-03 | 1.000e+00 | 0.000 | 6.933e-04 | 3.478e+00 |
| TDL-C | IDEAL | 90 | 4.296e-04 | 1.000e+00 | 0.000 | 6.933e-04 | NaN |
| TDL-D | ESTIMATED | 90 | 2.336e-04 | 1.000e+00 | 0.000 | 6.933e-04 | 3.201e+00 |
| TDL-D | IDEAL | 90 | 7.007e-05 | 5.000e-01 | 1107692.308 | 6.933e-04 | NaN |

## Figure References

- Global summary: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/results/phase5_publication/plots/phase5_global_packet_summary.png`
- Dynamic tradeoff: `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/results/phase5_publication/plots/phase5_dynamic_tradeoff.png`
- Representative packet tradeoffs:
  - `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/results/phase5_publication/plots/2x2_DYNAMIC-RAYLEIGH_CONV_QPSK_PHASE5_PACKET_TRADEOFF.png`
  - `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/results/phase5_publication/plots/2x2_DYNAMIC-RICIAN_LDPC_QPSK_PHASE5_PACKET_TRADEOFF.png`
  - `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/results/phase5_publication/plots/2x2_TDL-A_CONV_QPSK_PHASE5_PACKET_TRADEOFF.png`
- Representative CSI comparisons:
  - `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/results/phase5_publication/plots/2x2_DYNAMIC-RAYLEIGH_CONV_QPSK_PHASE5_CSI_COMPARISON.png`
  - `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/results/phase5_publication/plots/2x2_DYNAMIC-RICIAN_LDPC_QPSK_PHASE5_CSI_COMPARISON.png`
  - `/Users/coopersu/Documents/MATLAB/MIMO-OFDM信道编码 2/MIMO_OFDM_simulation-main/results/phase5_publication/plots/2x2_TDL-A_CONV_QPSK_PHASE5_CSI_COMPARISON.png`
