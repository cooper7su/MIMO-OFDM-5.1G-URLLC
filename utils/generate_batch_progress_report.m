function [reportPath, reportData] = generate_batch_progress_report(batchRoot, reportFilename)
%GENERATE_BATCH_PROGRESS_REPORT Build a Markdown summary for one batch run.

    if nargin < 2 || isempty(reportFilename)
        reportFilename = 'phase4_progress_report.md';
    end

    summaryPath = fullfile(batchRoot, 'batch_summary.mat');
    summaryData = load(summaryPath, 'batchSummary');
    batchSummary = summaryData.batchSummary;

    caseFiles = dir(fullfile(batchRoot, 'scenarios', '**', 'mat', '*.mat'));
    if ~isfield(batchSummary, 'num_scenarios')
        batchSummary.num_scenarios = numel(caseFiles);
    end
    if ~isfield(batchSummary, 'num_success')
        batchSummary.num_success = batchSummary.num_scenarios;
    end
    if ~isfield(batchSummary, 'num_failed')
        batchSummary.num_failed = 0;
    end
    rows = repmat(localEmptyRow(), 1, numel(caseFiles));

    for icase = 1:numel(caseFiles)
        casePath = fullfile(caseFiles(icase).folder, caseFiles(icase).name);
        caseData = load(casePath, 'cfg', 'mainResult');
        cfg = caseData.cfg;
        mainResult = caseData.mainResult;
        primary = mainResult.mode_results.(mainResult.primary_csi_mode);
        idx = numel(mainResult.EbN0s_dB);

        row = localEmptyRow();
        row.scenario = cfg.scenario_tag;
        row.mimo = sprintf('%dx%d', cfg.N_Tx, cfg.N_Rx);
        row.channel = upper(cfg.channel_model);
        row.coding = upper(cfg.Coded_method);
        row.modulation = cfg.mod_name;
        row.packet_length = localGetPacketLength(cfg);
        row.packet_bits = localGetNumericField(cfg, 'packet_length_bits', NaN);
        row.packet_symbols = localGetNumericField(cfg, 'packet_length_symbols', cfg.N_symbol);
        row.csi_mode = upper(mainResult.primary_csi_mode);
        row.estimator = localGetEstimatorLabel(cfg, mainResult);
        row.ber = primary.BER(idx);
        row.bler = primary.BLER(idx);
        row.throughput = primary.urlcc.effective_throughput_bps(idx);
        row.latency = primary.urlcc.latency_proxy_s(1);
        row.nmse = NaN;
        if isfield(primary, 'channel_nmse') && ~isempty(primary.channel_nmse)
            row.nmse = primary.channel_nmse(idx);
        end
        row.summary_plot = mainResult.figure_paths.summary;
        row.ber_plot = mainResult.figure_paths.ber;
        row.bler_plot = mainResult.figure_paths.bler;
        row.throughput_plot = mainResult.figure_paths.throughput;
        rows(icase) = row;
    end

    reportData = struct();
    reportData.batchSummary = batchSummary;
    reportData.rows = rows;
    reportData.report_generated_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

    reportLines = localBuildReportLines(batchRoot, batchSummary, rows, reportData.report_generated_at);
    reportText = strjoin(reportLines, newline);
    reportPath = fullfile(batchRoot, reportFilename);

    fid = fopen(reportPath, 'w');
    if fid < 0
        error('无法写入报告文件: %s', reportPath);
    end
    cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid, '%s\n', reportText);
end

function row = localEmptyRow()
    row = struct( ...
        'scenario', '', ...
        'mimo', '', ...
        'channel', '', ...
        'coding', '', ...
        'modulation', '', ...
        'packet_length', '', ...
        'packet_bits', NaN, ...
        'packet_symbols', NaN, ...
        'csi_mode', '', ...
        'estimator', '', ...
        'ber', NaN, ...
        'bler', NaN, ...
        'throughput', NaN, ...
        'latency', NaN, ...
        'nmse', NaN, ...
        'summary_plot', '', ...
        'ber_plot', '', ...
        'bler_plot', '', ...
        'throughput_plot', '');
end

function lines = localBuildReportLines(batchRoot, batchSummary, rows, generatedAt)
    lines = {};
    lines{end + 1} = sprintf('# %s', localReportTitle(batchSummary, batchRoot));
    lines{end + 1} = '';
    lines{end + 1} = sprintf('- Generated: %s', generatedAt);
    lines{end + 1} = sprintf('- Batch root: `%s`', batchRoot);
    lines{end + 1} = sprintf('- Sweep name: `%s`', batchSummary.sweep_name);
    lines{end + 1} = sprintf('- Scenarios: `%d`', batchSummary.num_scenarios);
    lines{end + 1} = sprintf('- Success: `%d`', batchSummary.num_success);
    lines{end + 1} = sprintf('- Failed: `%d`', batchSummary.num_failed);
    lines{end + 1} = sprintf('- MAT files: `%d`', numel(dir(fullfile(batchRoot, 'scenarios', '**', 'mat', '*.mat'))));
    lines{end + 1} = sprintf('- Plot files: `%d`', numel(dir(fullfile(batchRoot, 'scenarios', '**', 'plots', '*.png'))));
    lines{end + 1} = '';
    lines{end + 1} = '## Scenario Table';
    lines{end + 1} = '';
    lines{end + 1} = '| Scenario | MIMO | Channel | Coding | Mod | Packet | Bits | Symbols | CSI | Estimator | BER | BLER | Throughput (bps) | Latency (s) | NMSE | BER Plot | BLER Plot | Throughput Plot | Summary Plot |';
    lines{end + 1} = '| --- | --- | --- | --- | --- | --- | ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- |';

    for irow = 1:numel(rows)
        nmseText = 'N/A';
        if isfinite(rows(irow).nmse)
            nmseText = sprintf('%.3e', rows(irow).nmse);
        end
        lines{end + 1} = sprintf( ...
            '| %s | %s | %s | %s | %s | %s | %.0f | %.0f | %s | %s | %.3e | %.3e | %.3f | %.3e | %s | `%s` | `%s` | `%s` | `%s` |', ...
            rows(irow).scenario, rows(irow).mimo, rows(irow).channel, rows(irow).coding, ...
            rows(irow).modulation, rows(irow).packet_length, rows(irow).packet_bits, ...
            rows(irow).packet_symbols, rows(irow).csi_mode, rows(irow).estimator, rows(irow).ber, rows(irow).bler, ...
            rows(irow).throughput, rows(irow).latency, nmseText, rows(irow).ber_plot, ...
            rows(irow).bler_plot, rows(irow).throughput_plot, rows(irow).summary_plot);
    end
end

function value = localGetNumericField(cfg, fieldName, fallbackValue)
    value = fallbackValue;
    if isfield(cfg, fieldName) && ~isempty(cfg.(fieldName))
        value = cfg.(fieldName);
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

function estimator = localGetEstimatorLabel(cfg, mainResult)
    if strcmpi(mainResult.primary_csi_mode, 'ideal')
        estimator = 'IDEAL';
        return;
    end

    estimator = upper(char(cfg.channel_estimation_method));
end

function titleText = localReportTitle(batchSummary, batchRoot)
    lowerRoot = lower(batchRoot);
    if contains(lowerRoot, 'phase5') || contains(lower(batchSummary.sweep_name), 'phase5')
        titleText = 'Phase 5 Progress Report';
    else
        titleText = 'Phase 4 Progress Report';
    end
end
