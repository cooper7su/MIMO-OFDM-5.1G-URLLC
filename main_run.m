function [mainResult, validation, cfg] = main_run(varargin)
%MAIN_RUN Clear top-level entry point for one simulation scenario.

    setup_project_paths();
    cfg = default_config(varargin{:});

    mainResult = run_single_case(cfg);
    validation = run_validation_suite(cfg);
    results_file = save_run_artifacts(cfg, mainResult, validation);

    print_run_summary(cfg, mainResult, validation, results_file);
end

function results_file = save_run_artifacts(cfg, mainResult, validation)
    if ~exist(cfg.output_dir, 'dir')
        mkdir(cfg.output_dir);
    end

    cfg = make_serializable_cfg(cfg);
    if isfield(mainResult, 'cfg')
        mainResult.cfg = cfg;
    end

    results_file = fullfile(cfg.output_dir, cfg.output_matfile);
    save(results_file, 'cfg', 'mainResult', 'validation');
end

function print_run_summary(cfg, mainResult, validation, results_file)
    primaryMode = mainResult.primary_csi_mode;
    primaryResult = mainResult.mode_results.(primaryMode);

    fprintf('\n================ Main Scenario Summary ================\n');
    fprintf('Scenario : %s\n', mainResult.scenario_tag);
    fprintf('MIMO     : %dx%d\n', cfg.N_Tx, cfg.N_Rx);
    fprintf('Channel  : %s\n', cfg.channel_model);
    fprintf('Coding   : %s\n', cfg.Coded_method);
    if strcmpi(cfg.Coded_method, 'Conv')
        fprintf('Code rate: %.3f\n', cfg.code_rate);
    end
    fprintf('Mod      : %s\n', cfg.mod_name);
    fprintf('Packet   : %s | %d bits | %d OFDM symbols\n', ...
        cfg.packet_length_label, cfg.packet_length_bits, cfg.packet_length_symbols);
    fprintf('f_c      : %.2f GHz\n', cfg.f_carrier / 1e9);
    fprintf('Nfft/CP  : %d / %d\n', cfg.N_subcarrier, cfg.N_GI);
    fprintf('CSI mode : %s\n', upper(primaryMode));
    fprintf('Equalizer: %s\n', upper(cfg.equalizer_type));
    fprintf('BER plot : %s\n', mainResult.figure_paths.ber);
    fprintf('BLER plot: %s\n', mainResult.figure_paths.bler);
    fprintf('TP plot  : %s\n', mainResult.figure_paths.throughput);
    fprintf('Summary  : %s\n', mainResult.figure_paths.summary);
    fprintf('Data file: %s\n', results_file);
    fprintf('\nEb/N0(dB)\tBER\t\tBLER\t\tReliab.\t\tEff.TP(bps)\n');
    for i = 1:numel(mainResult.EbN0s_dB)
        fprintf('%6.0f\t\t%.3e\t%.3e\t%.3e\t%.3f\n', mainResult.EbN0s_dB(i), ...
            primaryResult.BER(i), primaryResult.BLER(i), ...
            primaryResult.urlcc.reliability(i), primaryResult.urlcc.effective_throughput_bps(i));
    end
    fprintf('\nThresholds:\n');
    for i = 1:numel(primaryResult.ber_metrics.thresholds)
        if isfinite(primaryResult.ber_metrics.reqSNR(i))
            fprintf('  BER=%s -> %.2f dB\n', ...
                primaryResult.ber_metrics.threshold_labels{i}, primaryResult.ber_metrics.reqSNR(i));
        else
            fprintf('  BER=%s -> not reached\n', primaryResult.ber_metrics.threshold_labels{i});
        end
    end
    fprintf('Score    : %.1f\n', primaryResult.ber_metrics.score);
    fprintf('Latency  : %.3e s\n', primaryResult.urlcc.latency_proxy_s(1));
    fprintf('Nom. TP  : %.3f bps\n', primaryResult.urlcc.nominal_throughput_bps(1));
    fprintf('Pilot OH : %.3f | Coding OH : %.3f\n', ...
        primaryResult.urlcc.pilot_overhead_ratio, primaryResult.urlcc.coding_overhead_ratio);
    for ithreshold = 1:numel(primaryResult.urlcc.bler_target_thresholds)
        fprintf('BLER<=%.0e @ %.1f dB : %d\n', ...
            primaryResult.urlcc.bler_target_thresholds(ithreshold), ...
            mainResult.EbN0s_dB(end), primaryResult.urlcc.reliability_target_met(ithreshold, end));
        fprintf('P(BLER<=%.0e)        : %.3f\n', ...
            primaryResult.urlcc.bler_target_thresholds(ithreshold), ...
            primaryResult.urlcc.reliability_target_confidence(ithreshold, end));
    end
    fprintf('BLER CI  : [%.3e, %.3e]\n', ...
        primaryResult.urlcc.bler_confidence_interval(1, end), ...
        primaryResult.urlcc.bler_confidence_interval(2, end));
    if any(strcmp(mainResult.csi_modes, 'estimated'))
        fprintf('Avg NMSE : %.3e\n', mean(mainResult.mode_results.estimated.channel_nmse, 'omitnan'));
    end
    if isfield(mainResult.comparison, 'ber_delta')
        fprintf('Cmp. BER delta (est-ideal) @ %.1f dB : %.3e\n', ...
            mainResult.EbN0s_dB(end), mainResult.comparison.ber_delta(end));
    end

    fprintf('\n================ Validation Summary ===================\n');
    fprintf('No-noise 1x1 roundtrip BER : %.3e\n', validation.no_noise_1x1.ber);
    fprintf('No-noise 2x1 roundtrip BER : %.3e\n', validation.no_noise_2x1.ber);
    fprintf('No-noise 2x2 roundtrip BER : %.3e\n', validation.no_noise_2x2.ber);
    fprintf('No-noise 2x4 roundtrip BER : %.3e\n', validation.no_noise_2x4.ber);
    fprintf('No-noise 4x4 roundtrip BER : %.3e\n', validation.no_noise_4x4.ber);
    fprintf('No-noise estimated-CSI BER : %.3e\n', validation.no_noise_estimated_csi.ber);
    fprintf('RS full-frame BER          : %.3e\n', validation.rs_full_frame.ber);
    fprintf('LDPC full-frame BER        : %.3e\n', validation.ldpc_full_frame.ber);
    fprintf('RS codec sanity passed     : %d\n', validation.rs_codec_sanity.passed);
    fprintf('LDPC codec sanity passed   : %d\n', validation.ldpc_codec_sanity.passed);
    fprintf('BPSK AWGN max theory gap   : %.3e\n', validation.awgn_theory.bpsk.max_abs_error);
    fprintf('QPSK AWGN max theory gap   : %.3e\n', validation.awgn_theory.qpsk.max_abs_error);
    fprintf('URLLC metric guard passed  : %d\n', validation.urlcc_metrics_guard.passed);
    fprintf('FBL packet guard passed    : %d\n', validation.finite_blocklength_guard.passed);
    fprintf('Dynamic channel smoke      : %d\n', validation.dynamic_channel_smoke.passed);
    fprintf('Dynamic TDL smoke          : %d\n', validation.dynamic_tdl_profiles_smoke.passed);
    fprintf('MMSE estimator smoke       : %d\n', validation.mmse_estimator_smoke.passed);
    fprintf('Kalman estimator smoke     : %d\n', validation.kalman_estimator_smoke.passed);
    fprintf('Bayesian estimator smoke   : %d\n', validation.bayesian_estimator_smoke.passed);
    fprintf('Score guard passed         : %d\n', validation.score_guard.passed);
    fprintf('Theory plot               : %s\n', validation.awgn_theory.figure_path);
    fprintf('======================================================\n');
end
