function [reportPath, auditData] = audit_phase4_results(outputRoot, options)
%AUDIT_PHASE4_RESULTS Audit Phase 4 batch outputs, plots, and regressions.

    if nargin < 1 || isempty(outputRoot)
        projectRoot = fileparts(fileparts(mfilename('fullpath')));
        outputRoot = fullfile(projectRoot, 'results', 'phase4_publication');
    end
    if nargin < 2 || isempty(options)
        options = struct();
    end
    options = localApplyDefaults(options);

    if ~exist(outputRoot, 'dir')
        mkdir(outputRoot);
    end

    auditData = struct();
    auditData.generated_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    auditData.output_root = outputRoot;
    auditData.batch_checks = repmat(localEmptyBatchCheck(), 1, numel(options.batch_roots));

    for ibatch = 1:numel(options.batch_roots)
        auditData.batch_checks(ibatch) = localAuditBatch(options.batch_roots{ibatch});
    end

    auditData.phase3_regression = localCompareBatchRoots( ...
        options.phase4_root, options.phase3_root, true);
    auditData.phase2_regression = localCompareBatchRoots( ...
        options.phase2_regression_root, options.phase2_root, false);

    reportPath = fullfile(outputRoot, options.report_filename);
    localWriteReport(reportPath, auditData, options.report_filename);
    save(fullfile(outputRoot, options.mat_filename), 'auditData');
end

function options = localApplyDefaults(options)
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    batchBase = fullfile(projectRoot, 'results', 'batch_sweeps');

    defaults = struct();
    defaults.phase4_root = fullfile(batchBase, 'phase4_full_matrix_smoke');
    defaults.phase3_root = fullfile(batchBase, 'phase3_full_matrix_smoke_v2');
    defaults.phase2_root = fullfile(batchBase, 'phase2_rician_smoke_v2');
    defaults.phase2_regression_root = fullfile(batchBase, 'phase4_phase2_regression');
    defaults.batch_roots = { ...
        fullfile(batchBase, 'phase4_full_matrix_smoke'), ...
        fullfile(batchBase, 'phase4_full_matrix_medium'), ...
        fullfile(batchBase, 'phase4_full_matrix_short'), ...
        fullfile(batchBase, 'phase4_phase2_regression')};
    defaults.report_filename = 'phase4_audit_report.md';
    defaults.mat_filename = 'phase4_audit_summary.mat';

    defaultFields = fieldnames(defaults);
    for ifield = 1:numel(defaultFields)
        fieldName = defaultFields{ifield};
        if ~isfield(options, fieldName) || isempty(options.(fieldName))
            options.(fieldName) = defaults.(fieldName);
        end
    end
end

function batchCheck = localAuditBatch(batchRoot)
    [rows, batchSummary] = collect_publication_rows(batchRoot);
    caseFiles = dir(fullfile(batchRoot, 'scenarios', '**', 'mat', '*.mat'));
    plotFiles = dir(fullfile(batchRoot, 'scenarios', '**', 'plots', '*.png'));

    batchCheck = localEmptyBatchCheck();
    batchCheck.sweep_name = batchSummary.sweep_name;
    batchCheck.batch_root = batchRoot;
    batchCheck.num_scenarios = batchSummary.num_scenarios;
    batchCheck.num_success = batchSummary.num_success;
    batchCheck.num_failed = batchSummary.num_failed;
    batchCheck.num_case_files = numel(caseFiles);
    batchCheck.num_plot_files = numel(plotFiles);
    batchCheck.num_rows = numel(rows);
    batchCheck.csi_modes = unique({rows.csi_mode});
    batchCheck.packet_lengths = unique({rows.packet_length});

    metricIssues = 0;
    missingFigures = 0;
    missingFields = 0;

    for irow = 1:numel(rows)
        row = rows(irow);
        seriesLength = numel(row.EbN0s_dB);
        if numel(row.BER) ~= seriesLength || ...
                numel(row.BLER) ~= seriesLength || ...
                numel(row.throughput_bps) ~= seriesLength || ...
                numel(row.latency_s) ~= seriesLength || ...
                numel(row.reliability) ~= seriesLength
            missingFields = missingFields + 1;
        end

        if any(row.BER < 0 | row.BLER < 0) || ...
                any(row.throughput_bps < 0) || ...
                any(row.latency_s <= 0) || ...
                any(row.reliability < 0 | row.reliability > 1) || ...
                any(row.reliability_target_confidence(:) < 0 | row.reliability_target_confidence(:) > 1)
            metricIssues = metricIssues + 1;
        end
    end

    for icase = 1:numel(caseFiles)
        caseData = load(fullfile(caseFiles(icase).folder, caseFiles(icase).name), 'mainResult');
        figurePaths = caseData.mainResult.figure_paths;
        expectedFields = {'ber', 'bler', 'throughput', 'summary'};
        for ifield = 1:numel(expectedFields)
            if ~isfield(figurePaths, expectedFields{ifield}) || ...
                    ~exist(figurePaths.(expectedFields{ifield}), 'file')
                missingFigures = missingFigures + 1;
            end
        end
    end

    batchCheck.missing_figure_count = missingFigures;
    batchCheck.missing_metric_field_count = missingFields;
    batchCheck.metric_issue_count = metricIssues;
    batchCheck.passed = batchCheck.num_case_files == batchCheck.num_scenarios && ...
        batchCheck.num_success == batchCheck.num_scenarios && ...
        batchCheck.num_failed == 0 && ...
        batchCheck.missing_figure_count == 0 && ...
        batchCheck.missing_metric_field_count == 0 && ...
        batchCheck.metric_issue_count == 0;
end

function comparison = localCompareBatchRoots(newRoot, oldRoot, keepLongOnly)
    newFiles = dir(fullfile(newRoot, 'scenarios', '**', 'mat', '*.mat'));
    if contains(oldRoot, 'phase2_rician_smoke_v2')
        oldFiles = dir(fullfile(oldRoot, 'mat', '**', '*.mat'));
    else
        oldFiles = dir(fullfile(oldRoot, 'scenarios', '**', 'mat', '*.mat'));
    end

    oldMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
    for ifile = 1:numel(oldFiles)
        oldMap(localStem(oldFiles(ifile).name)) = fullfile(oldFiles(ifile).folder, oldFiles(ifile).name);
    end

    comparison = struct();
    comparison.shared_count = 0;
    comparison.max_diff = 0;
    comparison.missing_tags = {};

    for ifile = 1:numel(newFiles)
        newTag = localStem(newFiles(ifile).name);
        if keepLongOnly && (endsWith(newTag, '_SHORT') || endsWith(newTag, '_MEDIUM'))
            continue;
        end
        if ~isKey(oldMap, newTag)
            comparison.missing_tags{end + 1} = newTag; %#ok<AGROW>
            continue;
        end

        newData = load(fullfile(newFiles(ifile).folder, newFiles(ifile).name), 'mainResult');
        oldData = load(oldMap(newTag), 'mainResult');
        thisDiff = max(abs(newData.mainResult.BER - oldData.mainResult.BER));
        comparison.max_diff = max(comparison.max_diff, thisDiff);
        comparison.shared_count = comparison.shared_count + 1;
    end

    comparison.passed = comparison.max_diff == 0 && isempty(comparison.missing_tags);
end

function localWriteReport(reportPath, auditData, reportFilename)
    lines = {};
    lines{end + 1} = sprintf('# %s', localAuditTitle(reportPath, reportFilename));
    lines{end + 1} = '';
    lines{end + 1} = sprintf('- Generated: %s', auditData.generated_at);
    lines{end + 1} = '';
    lines{end + 1} = '## Batch Checks';
    lines{end + 1} = '';
    lines{end + 1} = '| Sweep | Scenarios | Success | Failed | Rows | PNG | Missing Figures | Metric Issues | Passed |';
    lines{end + 1} = '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |';

    for ibatch = 1:numel(auditData.batch_checks)
        batchCheck = auditData.batch_checks(ibatch);
        lines{end + 1} = sprintf('| %s | %d | %d | %d | %d | %d | %d | %d | %d |', ...
            batchCheck.sweep_name, batchCheck.num_scenarios, batchCheck.num_success, ...
            batchCheck.num_failed, batchCheck.num_rows, batchCheck.num_plot_files, ...
            batchCheck.missing_figure_count, batchCheck.metric_issue_count, batchCheck.passed);
    end

    lines{end + 1} = '';
    lines{end + 1} = '## Regression';
    lines{end + 1} = '';
    lines{end + 1} = sprintf('- Phase 3 overlap shared count: `%d`', auditData.phase3_regression.shared_count);
    lines{end + 1} = sprintf('- Phase 3 overlap maxDiff: `%.3g`', auditData.phase3_regression.max_diff);
    lines{end + 1} = sprintf('- Phase 2 overlap shared count: `%d`', auditData.phase2_regression.shared_count);
    lines{end + 1} = sprintf('- Phase 2 overlap maxDiff: `%.3g`', auditData.phase2_regression.max_diff);

    fid = fopen(reportPath, 'w');
    if fid < 0
        error('无法写入审计报告: %s', reportPath);
    end
    cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid, '%s\n', strjoin(lines, newline));
end

function titleText = localAuditTitle(reportPath, reportFilename)
    lowerText = lower([reportPath ' ' reportFilename]);
    if contains(lowerText, 'phase5')
        titleText = 'Phase 5 Audit Report';
    else
        titleText = 'Phase 4 Audit Report';
    end
end

function batchCheck = localEmptyBatchCheck()
    batchCheck = struct( ...
        'sweep_name', '', ...
        'batch_root', '', ...
        'num_scenarios', 0, ...
        'num_success', 0, ...
        'num_failed', 0, ...
        'num_case_files', 0, ...
        'num_plot_files', 0, ...
        'num_rows', 0, ...
        'csi_modes', {{}}, ...
        'packet_lengths', {{}}, ...
        'missing_figure_count', 0, ...
        'missing_metric_field_count', 0, ...
        'metric_issue_count', 0, ...
        'passed', false);
end

function stem = localStem(fileName)
    [~, stem] = fileparts(fileName);
end
