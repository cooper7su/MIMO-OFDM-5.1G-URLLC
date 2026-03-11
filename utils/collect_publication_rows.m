function [rows, batchSummary] = collect_publication_rows(batchRoot)
%COLLECT_PUBLICATION_ROWS Load all case MAT files and flatten them per CSI mode.

    summaryData = load(fullfile(batchRoot, 'batch_summary.mat'), 'batchSummary');
    batchSummary = summaryData.batchSummary;
    caseFiles = dir(fullfile(batchRoot, 'scenarios', '**', 'mat', '*.mat'));

    rowsCell = cell(1, numel(caseFiles) * 2);
    rowCount = 0;
    for icase = 1:numel(caseFiles)
        casePath = fullfile(caseFiles(icase).folder, caseFiles(icase).name);
        caseData = load(casePath, 'cfg', 'mainResult');
        cfg = caseData.cfg;
        mainResult = caseData.mainResult;
        modeNames = fieldnames(mainResult.mode_results);

        for imode = 1:numel(modeNames)
            rowCount = rowCount + 1;
            rowsCell{rowCount} = localBuildRow(cfg, mainResult, ...
                mainResult.mode_results.(modeNames{imode}), modeNames{imode}, ...
                batchSummary.sweep_name, casePath);
        end
    end

    if rowCount == 0
        rows = repmat(localEmptyRow(), 0, 1);
        return;
    end
    rows = [rowsCell{1:rowCount}];
end

function row = localBuildRow(cfg, mainResult, modeResult, modeName, sweepName, casePath)
    urlcc = localResolveUrlcc(cfg, modeResult);

    row = localEmptyRow();
    row.scenario = cfg.scenario_tag;
    row.scenario_base = localScenarioBase(cfg.scenario_tag);
    row.source_batch = sweepName;
    row.case_mat_file = casePath;
    row.random_seed = localGetNumericField(cfg, 'random_seed', NaN);
    row.mimo = sprintf('%dx%d', cfg.N_Tx, cfg.N_Rx);
    row.N_Tx = cfg.N_Tx;
    row.N_Rx = cfg.N_Rx;
    row.channel = upper(cfg.channel_model);
    row.channel_model = cfg.channel_model;
    row.enable_dynamic_channel = localGetLogicalField(cfg, 'enable_dynamic_channel', false);
    row.use_fractional_delay = localGetLogicalField(cfg, 'use_fractional_delay', false);
    row.velocity_mps = localGetNumericField(cfg, 'velocity_mps', NaN);
    row.max_doppler_hz = localGetNumericField(cfg, 'max_doppler_hz', NaN);
    row.K_factor = localGetNumericField(cfg, 'K_factor', NaN);
    row.delay_spread_s = localGetNumericField(cfg, 'delay_spread_s', NaN);
    row.coding = upper(cfg.Coded_method);
    row.coded_method = cfg.Coded_method;
    row.code_rate = localGetNumericField(cfg, 'code_rate', NaN);
    row.modulation = cfg.mod_name;
    row.N_mod = cfg.N_mod;
    row.packet_length = localGetPacketLength(cfg);
    row.packet_bits = localGetNumericField(cfg, 'packet_length_bits', NaN);
    row.packet_symbols = localGetNumericField(cfg, 'packet_length_symbols', cfg.N_symbol);
    row.csi_mode = upper(modeName);
    row.primary_csi_mode = upper(mainResult.primary_csi_mode);
    row.enable_pilot_estimation = localGetLogicalField(cfg, 'enable_pilot_estimation', false);
    row.compare_csi_with_ideal = localGetLogicalField(cfg, 'compare_csi_with_ideal', false);
    row.channel_estimation_method = localGetEstimatorLabel(cfg, modeName);
    row.equalizer_type = localGetCharField(cfg, 'equalizer_type', '');
    row.pilot_amplitude = localGetNumericField(cfg, 'pilot_amplitude', NaN);
    row.pilot_interpolation = localGetCharField(cfg, 'pilot_interpolation', '');
    row.pilot_overhead_ratio = urlcc.pilot_overhead_ratio;
    row.pilot_overhead_time_s = urlcc.pilot_overhead_time_s;
    row.coding_overhead_ratio = urlcc.coding_overhead_ratio;
    row.EbN0s_dB = mainResult.EbN0s_dB;
    row.BER = modeResult.BER;
    row.BLER = modeResult.BLER;
    row.bler_confidence_interval = urlcc.bler_confidence_interval;
    row.throughput_bps = urlcc.effective_throughput_bps;
    row.nominal_throughput_bps = urlcc.nominal_throughput_bps;
    row.latency_s = urlcc.latency_proxy_s;
    row.reliability = urlcc.reliability;
    row.reliability_confidence_interval = urlcc.reliability_confidence_interval;
    row.reliability_target_thresholds = urlcc.bler_target_thresholds;
    row.reliability_target_met = urlcc.reliability_target_met;
    row.reliability_target_confidence = urlcc.reliability_target_confidence;
    row.reliability_tail_probability = urlcc.reliability_tail_probability;
    row.nmse = modeResult.channel_nmse;
    row.block_errors = modeResult.blockErrors;
    row.total_blocks = modeResult.totalBlocks;
    row.bit_errors = modeResult.bitErrors;
    row.total_bits = modeResult.totalBits;
    row.figure_paths = mainResult.figure_paths;
end

function urlcc = localResolveUrlcc(cfg, modeResult)
    if isfield(modeResult, 'urlcc') && ...
            isfield(modeResult.urlcc, 'bler_confidence_interval') && ...
            isfield(modeResult.urlcc, 'reliability_target_confidence')
        urlcc = modeResult.urlcc;
        return;
    end

    urlcc = compute_urlcc_metrics(cfg, modeResult.BLER, ...
        modeResult.blockErrors, modeResult.totalBlocks);
end

function row = localEmptyRow()
    row = struct( ...
        'scenario', '', ...
        'scenario_base', '', ...
        'source_batch', '', ...
        'case_mat_file', '', ...
        'random_seed', NaN, ...
        'mimo', '', ...
        'N_Tx', NaN, ...
        'N_Rx', NaN, ...
        'channel', '', ...
        'channel_model', '', ...
        'enable_dynamic_channel', false, ...
        'use_fractional_delay', false, ...
        'velocity_mps', NaN, ...
        'max_doppler_hz', NaN, ...
        'K_factor', NaN, ...
        'delay_spread_s', NaN, ...
        'coding', '', ...
        'coded_method', '', ...
        'code_rate', NaN, ...
        'modulation', '', ...
        'N_mod', NaN, ...
        'packet_length', '', ...
        'packet_bits', NaN, ...
        'packet_symbols', NaN, ...
        'csi_mode', '', ...
        'primary_csi_mode', '', ...
        'enable_pilot_estimation', false, ...
        'compare_csi_with_ideal', false, ...
        'channel_estimation_method', '', ...
        'equalizer_type', '', ...
        'pilot_amplitude', NaN, ...
        'pilot_interpolation', '', ...
        'pilot_overhead_ratio', NaN, ...
        'pilot_overhead_time_s', [], ...
        'coding_overhead_ratio', NaN, ...
        'EbN0s_dB', [], ...
        'BER', [], ...
        'BLER', [], ...
        'bler_confidence_interval', [], ...
        'throughput_bps', [], ...
        'nominal_throughput_bps', [], ...
        'latency_s', [], ...
        'reliability', [], ...
        'reliability_confidence_interval', [], ...
        'reliability_target_thresholds', [], ...
        'reliability_target_met', [], ...
        'reliability_target_confidence', [], ...
        'reliability_tail_probability', [], ...
        'nmse', [], ...
        'block_errors', [], ...
        'total_blocks', [], ...
        'bit_errors', [], ...
        'total_bits', [], ...
        'figure_paths', struct());
end

function value = localGetNumericField(cfg, fieldName, fallbackValue)
    value = fallbackValue;
    if isfield(cfg, fieldName) && ~isempty(cfg.(fieldName))
        value = cfg.(fieldName);
    end
end

function value = localGetLogicalField(cfg, fieldName, fallbackValue)
    value = fallbackValue;
    if isfield(cfg, fieldName) && ~isempty(cfg.(fieldName))
        value = logical(cfg.(fieldName));
    end
end

function value = localGetCharField(cfg, fieldName, fallbackValue)
    value = fallbackValue;
    if isfield(cfg, fieldName) && ~isempty(cfg.(fieldName))
        value = char(string(cfg.(fieldName)));
    end
end

function packetLength = localGetPacketLength(cfg)
    packetLength = 'LONG';
    if isfield(cfg, 'packet_length_label') && ~isempty(cfg.packet_length_label)
        packetLength = cfg.packet_length_label;
    elseif isfield(cfg, 'packet_length_mode') && ~isempty(cfg.packet_length_mode)
        packetLength = upper(char(cfg.packet_length_mode));
    end
end

function scenarioBase = localScenarioBase(scenarioTag)
    scenarioBase = regexprep(char(scenarioTag), '_(SHORT|MEDIUM)$', '');
end

function estimator = localGetEstimatorLabel(cfg, modeName)
    if strcmpi(modeName, 'ideal')
        estimator = 'IDEAL';
        return;
    end

    estimator = localGetCharField(cfg, 'channel_estimation_method', 'LS');
    if isempty(estimator)
        estimator = 'LS';
    else
        estimator = upper(estimator);
    end
end
