function cfg = default_config(varargin)
%DEFAULT_CONFIG Build the baseline research scenario configuration.

    project_root = fileparts(fileparts(mfilename('fullpath')));

    cfg = struct();
    cfg.project_root = project_root;
    cfg.output_dir = fullfile(project_root, 'results', 'codex_validation');
    cfg.output_matfile = 'main_run_results.mat';
    cfg.show_figures = false;
    cfg.save_pdf_figures = false;
    cfg.random_seed = 20260309;

    cfg.N_Tx = 2;
    cfg.N_Rx = 2;
    cfg.N_user = 1;
    cfg.N_symbol = 12;
    cfg.N_frame = 100;
    cfg.N_subcarrier = 1024;
    cfg.N_GI = 256;

    cfg.f_carrier = 5.1e9;
    cfg.f_sample = 15.36e6;
    cfg.index_used_base = [-300:-1, 1:300];
    cfg.index_pilot_base = [-300:25:-25, 25:25:300];

    cfg.channel_model = 'TDL-A';
    cfg.delay_spread_s = 100e-9;
    cfg.K_factor = 10;
    cfg.enable_dynamic_channel = false;
    cfg.use_fractional_delay = false;
    cfg.velocity_mps = 0;
    cfg.max_doppler_hz = [];
    cfg.doppler_spectrum = 'jakes';
    cfg.fractional_delay_span = 8;
    cfg.dynamic_fading_correlation = 0.98;
    cfg.dynamic_channel_update = 'symbol';

    cfg.N_mod = 2;
    cfg.Coded_method = 'Conv';
    cfg.code_rate = 1/3;
    cfg.enable_soft_viterbi = true;
    cfg.EbN0s_dB = 0:2:20;

    cfg.ldpc_matrix_path = fullfile(project_root, 'data', 'ldpc', 'H_336_672.mat');
    cfg.ldpc_validation_matrix_path = fullfile(project_root, 'data', 'ldpc', 'H_1920_3840.mat');
    cfg.ldpc_max_iterations = 20;
    cfg.rs_n = 255;
    cfg.rs_k = 223;
    cfg.rs_m = 8;

    cfg.enable_pilot_estimation = false;
    cfg.compare_csi_with_ideal = false;
    cfg.channel_estimation_method = 'LS';
    cfg.equalizer_type = 'ZF';
    cfg.pilot_amplitude = 1;
    cfg.pilot_interpolation = 'linear';
    cfg.pilot_time_interpolation = 'linear';
    cfg.estimation_prior_model = 'exponential';
    cfg.estimation_correlation_bins = [];
    cfg.estimation_correlation_symbols = [];
    cfg.kalman_process_scale = 0.05;
    cfg.kalman_measurement_scale = 1.0;
    cfg.kalman_initial_variance = 1.0;
    cfg.short_packet_mode = false;
    cfg.packet_length_mode = 'long';
    cfg.N_bits_per_packet = [];
    cfg.N_symbols_per_packet = [];
    cfg.packet_profiles = [];
    cfg.bler_target_thresholds = [1e-3, 1e-4];
    cfg.bler_confidence_level = 0.95;
    cfg.tail_probability_floor = 1e-9;

    cfg.scenario_name = '';

    cfg = apply_config_overrides(cfg, varargin{:});
    cfg = finalize_config(cfg);
end
