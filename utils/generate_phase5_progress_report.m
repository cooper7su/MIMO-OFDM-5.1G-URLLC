function reportPath = generate_phase5_progress_report(outputRoot, publicationData, auditData, plotSummary, options)
%GENERATE_PHASE5_PROGRESS_REPORT Write a concise Phase 5 delivery summary.

    if nargin < 1 || isempty(outputRoot)
        projectRoot = fileparts(fileparts(mfilename('fullpath')));
        outputRoot = fullfile(projectRoot, 'results', 'phase5_publication');
    end
    if nargin < 2 || isempty(publicationData)
        datasetFile = fullfile(outputRoot, 'phase5_publication_dataset.mat');
        data = load(datasetFile, 'publicationData');
        publicationData = data.publicationData;
    end
    if nargin < 3 || isempty(auditData)
        auditFile = fullfile(outputRoot, 'phase5_audit_summary.mat');
        data = load(auditFile, 'auditData');
        auditData = data.auditData;
    end
    if nargin < 4 || isempty(plotSummary)
        plotFile = fullfile(outputRoot, 'phase5_publication_plots.mat');
        data = load(plotFile, 'plotSummary');
        plotSummary = data.plotSummary;
    end
    if nargin < 5 || isempty(options)
        options = struct();
    end
    options = localApplyDefaults(options, outputRoot);

    rows = publicationData.rows;
    reportPath = fullfile(outputRoot, options.report_filename);
    lines = {};

    lines{end + 1} = '# Phase 5 Progress Report';
    lines{end + 1} = '';
    lines{end + 1} = sprintf('- Generated: %s', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
    lines{end + 1} = sprintf('- Publication dataset: `%s`', options.dataset_path);
    lines{end + 1} = sprintf('- Audit report: `%s`', options.audit_report_path);
    lines{end + 1} = '';

    lines{end + 1} = '## Coverage';
    lines{end + 1} = '';
    lines{end + 1} = sprintf('- Batch roots: `%d`', numel(options.batch_roots));
    lines{end + 1} = sprintf('- Scenario rows: `%d`', numel(rows));
    lines{end + 1} = sprintf('- MIMO configurations: `%s`', strjoin(localUniqueList({rows.mimo}), ', '));
    lines{end + 1} = sprintf('- Channels: `%s`', strjoin(localUniqueList({rows.channel}), ', '));
    lines{end + 1} = sprintf('- Coding modes: `%s`', strjoin(localUniqueList({rows.coding}), ', '));
    lines{end + 1} = sprintf('- Modulations: `%s`', strjoin(localUniqueList({rows.modulation}), ', '));
    lines{end + 1} = sprintf('- Packet lengths: `%s`', strjoin(localUniqueList({rows.packet_length}), ', '));
    lines{end + 1} = sprintf('- CSI modes: `%s`', strjoin(localUniqueList({rows.csi_mode}), ', '));
    lines{end + 1} = sprintf('- Estimators: `%s`', strjoin(localUniqueList({rows.channel_estimation_method}), ', '));
    lines{end + 1} = '';

    lines{end + 1} = '## Detailed Scenario Tables';
    lines{end + 1} = '';
    for ibatch = 1:numel(options.batch_roots)
        batchReport = localFindBatchReport(options.batch_roots{ibatch});
        if isempty(batchReport)
            lines{end + 1} = sprintf('- `%s`', options.batch_roots{ibatch});
        else
            lines{end + 1} = sprintf('- `%s` -> `%s`', options.batch_roots{ibatch}, batchReport);
        end
    end
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
    lines{end + 1} = '| Reference | Shared Scenarios | maxDiff | Passed |';
    lines{end + 1} = '| --- | ---: | ---: | --- |';
    lines{end + 1} = sprintf('| Phase 3 overlap | %d | %.3g | %d |', ...
        auditData.phase3_regression.shared_count, auditData.phase3_regression.max_diff, ...
        auditData.phase3_regression.passed);
    lines{end + 1} = sprintf('| Phase 2 overlap | %d | %.3g | %d |', ...
        auditData.phase2_regression.shared_count, auditData.phase2_regression.max_diff, ...
        auditData.phase2_regression.passed);
    lines{end + 1} = '';

    lines{end + 1} = '## Metric Summary By Channel';
    lines{end + 1} = '';
    lines{end + 1} = '| Channel | CSI | Rows | Median BER@max | Median BLER@max | Median TP@max (bps) | Median Latency (s) | Median NMSE@max |';
    lines{end + 1} = '| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |';
    channelModes = localUniqueList({rows.channel});
    csiModes = {'ESTIMATED', 'IDEAL'};
    for ichannel = 1:numel(channelModes)
        for icsi = 1:numel(csiModes)
            subset = rows(strcmp({rows.channel}, channelModes{ichannel}) & strcmp({rows.csi_mode}, csiModes{icsi}));
            if isempty(subset)
                continue;
            end
            [medianBer, medianBler, medianTp, medianLatency, medianNmse] = localSummarizeRows(subset);
            lines{end + 1} = sprintf('| %s | %s | %d | %.3e | %.3e | %.3f | %.3e | %.3e |', ...
                channelModes{ichannel}, csiModes{icsi}, numel(subset), ...
                medianBer, medianBler, medianTp, medianLatency, medianNmse);
        end
    end
    lines{end + 1} = '';

    lines{end + 1} = '## Figure References';
    lines{end + 1} = '';
    lines{end + 1} = sprintf('- Global summary: `%s`', localFirstPath(plotSummary.global_summary_paths));
    lines{end + 1} = sprintf('- Dynamic tradeoff: `%s`', plotSummary.dynamic_tradeoff_path);
    lines = [lines localPrefixList('Representative packet tradeoffs', plotSummary.packet_tradeoff_paths)]; %#ok<AGROW>
    lines = [lines localPrefixList('Representative CSI comparisons', plotSummary.csi_comparison_paths)]; %#ok<AGROW>

    fid = fopen(reportPath, 'w');
    if fid < 0
        error('无法写入 Phase 5 进展报告: %s', reportPath);
    end
    cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid, '%s\n', strjoin(lines, newline));
end

function options = localApplyDefaults(options, outputRoot)
    defaults = struct();
    defaults.batch_roots = {};
    defaults.dataset_path = fullfile(outputRoot, 'phase5_publication_dataset.mat');
    defaults.audit_report_path = fullfile(outputRoot, 'phase5_audit_report.md');
    defaults.report_filename = 'phase5_progress_report.md';

    defaultFields = fieldnames(defaults);
    for ifield = 1:numel(defaultFields)
        fieldName = defaultFields{ifield};
        if ~isfield(options, fieldName) || isempty(options.(fieldName))
            options.(fieldName) = defaults.(fieldName);
        end
    end
end

function values = localUniqueList(items)
    if isempty(items)
        values = {};
        return;
    end
    items = items(~cellfun(@isempty, items));
    if isempty(items)
        values = {};
        return;
    end
    values = unique(cellfun(@char, items, 'UniformOutput', false));
end

function [medianBer, medianBler, medianTp, medianLatency, medianNmse] = localSummarizeRows(rows)
    medianBer = median(arrayfun(@(r) r.BER(end), rows), 'omitnan');
    medianBler = median(arrayfun(@(r) r.BLER(end), rows), 'omitnan');
    medianTp = median(arrayfun(@(r) r.throughput_bps(end), rows), 'omitnan');
    medianLatency = median(arrayfun(@(r) r.latency_s(1), rows), 'omitnan');
    medianNmse = median(arrayfun(@(r) localTailValue(r.nmse), rows), 'omitnan');
end

function value = localTailValue(series)
    if isempty(series)
        value = NaN;
    else
        value = series(end);
    end
end

function pathOut = localFirstPath(pathList)
    pathOut = '';
    if isempty(pathList)
        return;
    end
    if iscell(pathList)
        pathOut = pathList{1};
    else
        pathOut = pathList;
    end
end

function lines = localPrefixList(titleText, pathList)
    lines = {};
    lines{end + 1} = sprintf('- %s:', titleText);
    if isempty(pathList)
        lines{end + 1} = '  - none';
        return;
    end

    for ipath = 1:numel(pathList)
        lines{end + 1} = sprintf('  - `%s`', pathList{ipath});
    end
end

function reportPath = localFindBatchReport(batchRoot)
    reportPath = '';
    phase5Report = fullfile(batchRoot, 'phase5_progress_report.md');
    phase4Report = fullfile(batchRoot, 'phase4_progress_report.md');
    if exist(phase5Report, 'file')
        reportPath = phase5Report;
    elseif exist(phase4Report, 'file')
        reportPath = phase4Report;
    end
end
