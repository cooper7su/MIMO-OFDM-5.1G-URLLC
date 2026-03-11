function batchSummary = main_batch(batchOptions)
%MAIN_BATCH Run the experimental sweep infrastructure and save all artifacts.
%   batchSummary = MAIN_BATCH() runs the default 24-scenario long-packet sweep:
%   MIMO {2x1, 2x2} x Modulation {BPSK, QPSK} x Coding {Conv, RS, LDPC}
%   x Channel {AWGN, TDL-A}. Results are stored under:
%   results/batch_sweeps/<sweep_name>/scenarios/<CHANNEL>/<SCENARIO>/{mat,plots}
%
%   batchSummary = MAIN_BATCH(opts) accepts a structure with optional fields:
%   - EbN0s_dB
%   - N_frame
%   - random_seed
%   - deterministic_per_scenario
%   - sweep_name
%   - output_root
%   - run_component_checks
%   - include_rician
%   - rician_K_factor
%   - enable_dynamic_channel
%   - use_fractional_delay
%   - velocity_mps
%   - max_doppler_hz
%   - enable_pilot_estimation
%   - compare_csi_with_ideal
%   - channel_estimation_method
%   - equalizer_type
%   - short_packet_mode
%   - packet_length_modes
%   - generate_progress_report
%   - report_filename
%   - generate_publication_dataset
%   - publication_dataset_filename
%   - save_pdf_figures
%   - mimo_modes
%   - modulation_orders
%   - coding_modes
%   - channel_modes
%   - scenario_overrides_list

    setup_project_paths();

    if nargin < 1 || isempty(batchOptions)
        batchOptions = struct();
    end

    batchOptions = local_apply_batch_defaults(batchOptions);
    outputDirs = local_prepare_output_dirs(batchOptions);
    batchOptions.output_root = fileparts(outputDirs.root);

    batchSummary = struct();
    batchSummary.sweep_name = batchOptions.sweep_name;
    batchSummary.created_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    batchSummary.output_dirs = outputDirs;
    batchSummary.batch_options = batchOptions;
    batchSummary.component_checks = struct();
    batchSummary.scenarios = struct([]);
    batchSummary.progress_report_path = '';
    batchSummary.publication_dataset_path = '';

    if batchOptions.run_component_checks
        sanityCfg = default_config('show_figures', false);
        fprintf('Running batch preflight component checks...\n');
        batchSummary.component_checks.rs = run_rs_codec_sanity();
        batchSummary.component_checks.ldpc = run_ldpc_codec_sanity(sanityCfg);
        fprintf('Component checks | RS=%d | LDPC=%d\n', ...
            batchSummary.component_checks.rs.passed, ...
            batchSummary.component_checks.ldpc.passed);
    end

    scenarioOverridesList = local_build_scenario_overrides(batchOptions);
    numScenarios = numel(scenarioOverridesList);
    summaryFile = fullfile(outputDirs.root, 'batch_summary.mat');
    batchSummary.scenarios = repmat(local_empty_case_record(), 1, numScenarios);

    fprintf('\n================ Batch Sweep Start ====================\n');
    fprintf('Sweep name : %s\n', batchOptions.sweep_name);
    fprintf('Scenarios  : %d\n', numScenarios);
    fprintf('Case root  : %s\n', fullfile(outputDirs.root, 'scenarios'));
    fprintf('======================================================\n');

    for iscenario = 1:numScenarios
        scenarioOverrides = scenarioOverridesList{iscenario};
        scenarioSeed = batchOptions.random_seed;
        if batchOptions.deterministic_per_scenario
            scenarioSeed = batchOptions.random_seed + iscenario - 1;
        end

        scenarioOverrides.random_seed = scenarioSeed;
        previewCfg = default_config(scenarioOverrides);
        caseOutputDirs = local_prepare_case_output_dirs(outputDirs, previewCfg);
        scenarioOverrides.output_dir = caseOutputDirs.root;
        scenarioOverrides.plot_output_dir = caseOutputDirs.plots;
        cfg = default_config(scenarioOverrides);
        cfg.output_matfile = sprintf('%s.mat', cfg.scenario_tag);
        cfg.plot_filename = sprintf('%s.png', cfg.scenario_tag);

        caseMatFile = fullfile(caseOutputDirs.mat, cfg.output_matfile);
        fprintf('\n[%02d/%02d] %s | seed=%d\n', ...
            iscenario, numScenarios, cfg.scenario_tag, cfg.random_seed);

        tic;
        try
            mainResult = run_single_case(cfg);
            elapsedSeconds = toc;

            caseRecord = local_empty_case_record();
            caseRecord.status = 'success';
            caseRecord.scenario_tag = cfg.scenario_tag;
            caseRecord.case_index = iscenario;
            caseRecord.random_seed = cfg.random_seed;
            caseRecord.runtime_seconds = elapsedSeconds;
            caseRecord.result_mat_file = caseMatFile;
            caseRecord.figure_path = mainResult.figure_path;
            caseRecord.figure_paths = mainResult.figure_paths;
            caseRecord.minBER = min(mainResult.BER);
            caseRecord.minBLER = min(mainResult.BLER);
            caseRecord.maxThroughput_bps = max(mainResult.effectiveThroughput_bps);
            caseRecord.maxReliability = max(mainResult.reliability);
            caseRecord.primary_csi_mode = mainResult.primary_csi_mode;
            caseRecord.csi_modes = mainResult.csi_modes;
            caseRecord.packet_length_mode = cfg.packet_length_mode;
            caseRecord.packet_length_bits = cfg.packet_length_bits;
            caseRecord.packet_length_symbols = cfg.packet_length_symbols;
            caseRecord.metrics = mainResult.metrics;
            cfg_to_save = make_serializable_cfg(cfg);
            mainResult.cfg = cfg_to_save;
            caseRecord.cfg = cfg_to_save;
            cfg = cfg_to_save;
            save(caseMatFile, 'cfg', 'mainResult', 'caseRecord');
            batchSummary.scenarios(iscenario) = caseRecord;

            fprintf('Completed %s | runtime=%.2fs | min BER=%.3e\n', ...
                cfg.scenario_tag, elapsedSeconds, caseRecord.minBER);
        catch ME
            elapsedSeconds = toc;

            caseRecord = local_empty_case_record();
            caseRecord.status = 'failed';
            caseRecord.scenario_tag = cfg.scenario_tag;
            caseRecord.case_index = iscenario;
            caseRecord.random_seed = cfg.random_seed;
            caseRecord.runtime_seconds = elapsedSeconds;
            caseRecord.result_mat_file = caseMatFile;
            caseRecord.figure_path = '';
            caseRecord.figure_paths = struct();
            caseRecord.minBER = NaN;
            caseRecord.minBLER = NaN;
            caseRecord.maxThroughput_bps = NaN;
            caseRecord.maxReliability = NaN;
            caseRecord.primary_csi_mode = '';
            caseRecord.csi_modes = {};
            caseRecord.packet_length_mode = '';
            caseRecord.packet_length_bits = NaN;
            caseRecord.packet_length_symbols = NaN;
            caseRecord.metrics = struct();
            caseRecord.cfg = make_serializable_cfg(cfg);
            caseRecord.error_identifier = ME.identifier;
            caseRecord.error_message = ME.message;
            batchSummary.scenarios(iscenario) = caseRecord;

            fprintf(2, 'Failed %s | runtime=%.2fs | %s\n', ...
                cfg.scenario_tag, elapsedSeconds, ME.message);
        end

        batchSummary.last_completed_index = iscenario;
        batchSummary.updated_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
        save(summaryFile, 'batchSummary');
    end

    statuses = {batchSummary.scenarios.status};
    batchSummary.num_scenarios = numScenarios;
    batchSummary.num_success = sum(strcmp(statuses, 'success'));
    batchSummary.num_failed = sum(strcmp(statuses, 'failed'));
    batchSummary.completed_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    save(summaryFile, 'batchSummary');

    if batchOptions.generate_progress_report
        try
            reportPath = generate_batch_progress_report(outputDirs.root, batchOptions.report_filename);
            batchSummary.progress_report_path = reportPath;
        catch ME
            batchSummary.progress_report_path = '';
            batchSummary.progress_report_error = ME.message;
            fprintf(2, 'Progress report generation failed: %s\n', ME.message);
        end
    end

    if batchOptions.generate_publication_dataset
        try
            datasetPath = generate_publication_dataset(outputDirs.root, batchOptions.publication_dataset_filename);
            batchSummary.publication_dataset_path = datasetPath;
        catch ME
            batchSummary.publication_dataset_path = '';
            batchSummary.publication_dataset_error = ME.message;
            fprintf(2, 'Publication dataset generation failed: %s\n', ME.message);
        end
    end

    save(summaryFile, 'batchSummary');

    fprintf('\n================ Batch Sweep Summary ==================\n');
    fprintf('Sweep name : %s\n', batchSummary.sweep_name);
    fprintf('Success    : %d\n', batchSummary.num_success);
    fprintf('Failed     : %d\n', batchSummary.num_failed);
    fprintf('Summary    : %s\n', summaryFile);
    if ~isempty(batchSummary.progress_report_path)
        fprintf('Report     : %s\n', batchSummary.progress_report_path);
    end
    if ~isempty(batchSummary.publication_dataset_path)
        fprintf('Dataset    : %s\n', batchSummary.publication_dataset_path);
    end
    fprintf('======================================================\n');
end

function batchOptions = local_apply_batch_defaults(batchOptions)
    defaults = struct();
    defaults.EbN0s_dB = [];
    defaults.N_frame = [];
    defaults.random_seed = 20260309;
    defaults.deterministic_per_scenario = true;
    defaults.sweep_name = ['full_sweep_' datestr(now, 'yyyymmdd_HHMMSS')];
    defaults.output_root = '';
    defaults.run_component_checks = true;
    defaults.include_rician = false;
    defaults.rician_K_factor = 10;
    defaults.enable_dynamic_channel = false;
    defaults.use_fractional_delay = false;
    defaults.velocity_mps = 0;
    defaults.max_doppler_hz = [];
    defaults.enable_pilot_estimation = false;
    defaults.compare_csi_with_ideal = false;
    defaults.channel_estimation_method = 'LS';
    defaults.equalizer_type = 'ZF';
    defaults.short_packet_mode = false;
    defaults.packet_length_modes = {'long'};
    defaults.generate_progress_report = true;
    defaults.report_filename = 'phase4_progress_report.md';
    defaults.generate_publication_dataset = true;
    defaults.publication_dataset_filename = 'phase4_publication_dataset.mat';
    defaults.save_pdf_figures = false;
    defaults.mimo_modes = [2 1; 2 2];
    defaults.modulation_orders = [1 2];
    defaults.coding_modes = {'Conv', 'RS', 'LDPC'};
    defaults.channel_modes = {'AWGN', 'TDL-A'};
    defaults.scenario_overrides_list = {};
    defaults.show_figures = false;

    defaultFields = fieldnames(defaults);
    for ifield = 1:numel(defaultFields)
        fieldName = defaultFields{ifield};
        if ~isfield(batchOptions, fieldName) || isempty(batchOptions.(fieldName))
            batchOptions.(fieldName) = defaults.(fieldName);
        end
    end

    if batchOptions.include_rician && ...
            ~any(strcmpi(batchOptions.channel_modes, 'Rician'))
        batchOptions.channel_modes{end + 1} = 'Rician';
    end
end

function outputDirs = local_prepare_output_dirs(batchOptions)
    projectRoot = fileparts(mfilename('fullpath'));
    if isempty(batchOptions.output_root)
        batchOptions.output_root = fullfile(projectRoot, 'results', 'batch_sweeps');
    end

    outputDirs = struct();
    outputDirs.root = fullfile(batchOptions.output_root, batchOptions.sweep_name);
    outputDirs.mat = fullfile(outputDirs.root, 'mat');
    outputDirs.plots = fullfile(outputDirs.root, 'plots');

    if ~exist(outputDirs.root, 'dir'), mkdir(outputDirs.root); end
    if ~exist(outputDirs.mat, 'dir'), mkdir(outputDirs.mat); end
    if ~exist(outputDirs.plots, 'dir'), mkdir(outputDirs.plots); end
end

function caseOutputDirs = local_prepare_case_output_dirs(outputDirs, cfg)
    channelFolder = local_channel_folder(cfg);
    caseOutputDirs = struct();
    caseOutputDirs.root = fullfile(outputDirs.root, 'scenarios', channelFolder, cfg.scenario_tag);
    caseOutputDirs.mat = fullfile(caseOutputDirs.root, 'mat');
    caseOutputDirs.plots = fullfile(caseOutputDirs.root, 'plots');

    if ~exist(caseOutputDirs.root, 'dir'), mkdir(caseOutputDirs.root); end
    if ~exist(caseOutputDirs.mat, 'dir'), mkdir(caseOutputDirs.mat); end
    if ~exist(caseOutputDirs.plots, 'dir'), mkdir(caseOutputDirs.plots); end
end

function channelFolder = local_channel_folder(cfg)
    channelFolder = upper(cfg.channel_model);
    if isfield(cfg, 'enable_dynamic_channel') && cfg.enable_dynamic_channel && ...
            startsWith(channelFolder, 'TDL-', 'IgnoreCase', true)
        channelFolder = [channelFolder '-DYN'];
    end
end

function scenarioOverridesList = local_build_scenario_overrides(batchOptions)
    if ~isempty(batchOptions.scenario_overrides_list)
        scenarioOverridesList = batchOptions.scenario_overrides_list;
        return;
    end

    scenarioOverridesList = {};
    packetModes = local_order_packet_modes(batchOptions.packet_length_modes);
    for ipacket = 1:numel(packetModes)
        scenarioOverridesList = local_append_packet_mode_group( ...
            scenarioOverridesList, batchOptions, packetModes{ipacket});
    end
end

function scenarioOverridesList = local_append_packet_mode_group( ...
        scenarioOverridesList, batchOptions, packetMode)
    codingModes = batchOptions.coding_modes;
    channelModes = batchOptions.channel_modes;
    modulationOrders = batchOptions.modulation_orders;
    mimoModes = batchOptions.mimo_modes;
    legacyMimoModes = [2 1; 2 2];
    legacyNonRicianChannels = local_intersect_channel_order(channelModes, {'AWGN', 'TDL-A'});
    legacyRicianChannels = local_intersect_channel_order(channelModes, {'Rician'});

    % Keep the Phase 2 overlap subset first so deterministic seeds remain unchanged.
    scenarioOverridesList = local_append_selected_modes( ...
        scenarioOverridesList, legacyNonRicianChannels, codingModes, modulationOrders, ...
        legacyMimoModes, batchOptions, true, packetMode);
    scenarioOverridesList = local_append_selected_modes( ...
        scenarioOverridesList, legacyRicianChannels, codingModes, modulationOrders, ...
        legacyMimoModes, batchOptions, true, packetMode);

    nonRicianChannels = channelModes(~strcmpi(channelModes, 'Rician'));
    ricianChannels = channelModes(strcmpi(channelModes, 'Rician'));

    scenarioOverridesList = local_append_channel_group( ...
        scenarioOverridesList, nonRicianChannels, codingModes, modulationOrders, mimoModes, batchOptions, packetMode);
    scenarioOverridesList = local_append_channel_group( ...
        scenarioOverridesList, ricianChannels, codingModes, modulationOrders, mimoModes, batchOptions, packetMode);
end

function scenarioOverridesList = local_append_channel_group( ...
        scenarioOverridesList, channelModes, codingModes, modulationOrders, mimoModes, batchOptions, packetMode)
    scenarioOverridesList = local_append_selected_modes( ...
        scenarioOverridesList, channelModes, codingModes, modulationOrders, mimoModes, batchOptions, false, packetMode);
end

function scenarioOverridesList = local_append_selected_modes( ...
        scenarioOverridesList, channelModes, codingModes, modulationOrders, mimoModes, batchOptions, legacyOnly, packetMode)
    for imimo = 1:size(mimoModes, 1)
        N_Tx = mimoModes(imimo, 1);
        N_Rx = mimoModes(imimo, 2);
        if ~local_has_mimo_mode(batchOptions.mimo_modes, N_Tx, N_Rx)
            continue;
        end
        for ichannel = 1:numel(channelModes)
            isLegacyPhase2Case = local_is_phase2_overlap_case(N_Tx, N_Rx, channelModes{ichannel});
            if legacyOnly && ~isLegacyPhase2Case
                continue;
            end
            if ~legacyOnly && isLegacyPhase2Case
                continue;
            end
            for icoding = 1:numel(codingModes)
                for imod = 1:numel(modulationOrders)
                    N_mod = modulationOrders(imod);
                    modName = local_modulation_name(N_mod);
                    scenarioName = local_build_scenario_name( ...
                        N_Tx, N_Rx, channelModes{ichannel}, codingModes{icoding}, ...
                        modName, packetMode, batchOptions);

                    overrides = struct();
                    overrides.N_Tx = N_Tx;
                    overrides.N_Rx = N_Rx;
                    overrides.channel_model = channelModes{ichannel};
                    overrides.Coded_method = codingModes{icoding};
                    overrides.N_mod = N_mod;
                    overrides.scenario_name = scenarioName;
                    overrides.packet_length_mode = packetMode;
                    overrides.show_figures = batchOptions.show_figures;
                    overrides.save_pdf_figures = batchOptions.save_pdf_figures;
                    overrides.enable_dynamic_channel = batchOptions.enable_dynamic_channel;
                    overrides.use_fractional_delay = batchOptions.use_fractional_delay;
                    overrides.velocity_mps = batchOptions.velocity_mps;
                    overrides.max_doppler_hz = batchOptions.max_doppler_hz;
                    overrides.enable_pilot_estimation = batchOptions.enable_pilot_estimation;
                    overrides.compare_csi_with_ideal = batchOptions.compare_csi_with_ideal;
                    overrides.channel_estimation_method = batchOptions.channel_estimation_method;
                    overrides.equalizer_type = batchOptions.equalizer_type;
                    overrides.short_packet_mode = batchOptions.short_packet_mode;
                    if strcmpi(channelModes{ichannel}, 'Rician')
                        overrides.K_factor = batchOptions.rician_K_factor;
                    end

                    if ~isempty(batchOptions.EbN0s_dB)
                        overrides.EbN0s_dB = batchOptions.EbN0s_dB;
                    end
                    if ~isempty(batchOptions.N_frame)
                        overrides.N_frame = batchOptions.N_frame;
                    end
                    if strcmpi(codingModes{icoding}, 'Conv')
                        overrides.code_rate = 1/3;
                    end

                    scenarioOverridesList{end + 1} = overrides; %#ok<AGROW>
                end
            end
        end
    end
end

function scenarioName = local_build_scenario_name( ...
        N_Tx, N_Rx, channelMode, codingMode, modName, packetMode, batchOptions)
    channelLabel = upper(channelMode);
    if batchOptions.enable_dynamic_channel && startsWith(channelLabel, 'TDL-', 'IgnoreCase', true)
        channelLabel = [channelLabel '-DYN'];
    end
    scenarioName = sprintf('%dx%d_%s_%s_%s', ...
        N_Tx, N_Rx, channelLabel, upper(codingMode), modName);
    if ~strcmpi(packetMode, 'long')
        scenarioName = sprintf('%s_%s', scenarioName, upper(packetMode));
    end
end

function tf = local_has_mimo_mode(mimoModes, N_Tx, N_Rx)
    tf = any(mimoModes(:, 1) == N_Tx & mimoModes(:, 2) == N_Rx);
end

function tf = local_is_phase2_overlap_case(N_Tx, N_Rx, channelMode)
    tf = (N_Tx == 2) && any(N_Rx == [1 2]) && ...
        any(strcmpi(channelMode, {'AWGN', 'TDL-A', 'Rician'}));
end

function orderedChannels = local_intersect_channel_order(channelModes, targetChannels)
    orderedChannels = {};
    for ichannel = 1:numel(channelModes)
        if any(strcmpi(channelModes{ichannel}, targetChannels))
            orderedChannels{end + 1} = channelModes{ichannel}; %#ok<AGROW>
        end
    end
end

function orderedPacketModes = local_order_packet_modes(packetModes)
    if isstring(packetModes)
        packetModes = cellstr(packetModes);
    end
    packetModes = packetModes(:).';

    orderedPacketModes = {};
    preferredOrder = {'long', 'medium', 'short'};
    for iorder = 1:numel(preferredOrder)
        for imode = 1:numel(packetModes)
            if strcmpi(packetModes{imode}, preferredOrder{iorder})
                orderedPacketModes{end + 1} = lower(packetModes{imode}); %#ok<AGROW>
            end
        end
    end
    for imode = 1:numel(packetModes)
        if ~any(strcmpi(packetModes{imode}, orderedPacketModes))
            orderedPacketModes{end + 1} = lower(packetModes{imode}); %#ok<AGROW>
        end
    end
end

function modName = local_modulation_name(N_mod)
    switch N_mod
        case 1
            modName = 'BPSK';
        case 2
            modName = 'QPSK';
        otherwise
            modName = sprintf('%d-bit', N_mod);
    end
end

function caseRecord = local_empty_case_record()
    caseRecord = struct( ...
        'status', '', ...
        'scenario_tag', '', ...
        'case_index', NaN, ...
        'random_seed', NaN, ...
        'runtime_seconds', NaN, ...
        'result_mat_file', '', ...
        'figure_path', '', ...
        'figure_paths', struct(), ...
        'minBER', NaN, ...
        'minBLER', NaN, ...
        'maxThroughput_bps', NaN, ...
        'maxReliability', NaN, ...
        'primary_csi_mode', '', ...
        'csi_modes', {{}}, ...
        'packet_length_mode', '', ...
        'packet_length_bits', NaN, ...
        'packet_length_symbols', NaN, ...
        'metrics', struct(), ...
        'cfg', struct(), ...
        'error_identifier', '', ...
        'error_message', '');
end
