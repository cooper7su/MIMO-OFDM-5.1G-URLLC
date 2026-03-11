function plotSummary = generate_phase4_publication_plots(datasetPath, outputDir, options)
%GENERATE_PHASE4_PUBLICATION_PLOTS Export unified Phase 4 publication figures.

    if nargin < 1 || isempty(datasetPath)
        projectRoot = fileparts(fileparts(mfilename('fullpath')));
        datasetPath = fullfile(projectRoot, 'results', 'phase4_publication', 'publication_dataset.mat');
    end
    if nargin < 2 || isempty(outputDir)
        outputDir = fullfile(fileparts(datasetPath), 'plots');
    end
    if nargin < 3 || isempty(options)
        options = struct();
    end
    options = localApplyDefaults(options);

    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    data = load(datasetPath, 'publicationData');
    rows = data.publicationData.rows;
    plotSummary = struct();
    plotSummary.generated_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    plotSummary.dataset_path = datasetPath;
    plotSummary.output_dir = outputDir;
    plotSummary.packet_tradeoff_paths = {};
    plotSummary.csi_comparison_paths = {};

    plotSummary.global_summary_paths = localGenerateGlobalSummary(rows, outputDir, options);

    scenarioBases = localSelectScenarioBases(rows, options.representative_scenarios);
    for iscenario = 1:numel(scenarioBases)
        packetPath = localGeneratePacketTradeoffFigure(rows, scenarioBases{iscenario}, outputDir, options);
        if ~isempty(packetPath)
            plotSummary.packet_tradeoff_paths{end + 1} = packetPath; %#ok<AGROW>
        end

        csiPath = localGenerateCsiComparisonFigure(rows, scenarioBases{iscenario}, outputDir, options);
        if ~isempty(csiPath)
            plotSummary.csi_comparison_paths{end + 1} = csiPath; %#ok<AGROW>
        end
    end

    save(fullfile(fileparts(datasetPath), 'phase4_publication_plots.mat'), 'plotSummary');
end

function options = localApplyDefaults(options)
    defaults = struct();
    defaults.save_pdf = true;
    defaults.representative_scenarios = { ...
        '2x2_TDL-A_CONV_QPSK', ...
        '2x2_RICIAN_LDPC_QPSK', ...
        '4x4_AWGN_LDPC_QPSK'};

    defaultFields = fieldnames(defaults);
    for ifield = 1:numel(defaultFields)
        fieldName = defaultFields{ifield};
        if ~isfield(options, fieldName) || isempty(options.(fieldName))
            options.(fieldName) = defaults.(fieldName);
        end
    end
end

function scenarioBases = localSelectScenarioBases(rows, requestedScenarios)
    available = unique({rows.scenario_base});
    scenarioBases = {};
    for iscenario = 1:numel(requestedScenarios)
        if any(strcmp(available, requestedScenarios{iscenario}))
            scenarioBases{end + 1} = requestedScenarios{iscenario}; %#ok<AGROW>
        end
    end
end

function pathOut = localGeneratePacketTradeoffFigure(rows, scenarioBase, outputDir, options)
    packetOrder = {'LONG', 'MEDIUM', 'SHORT'};
    rowSet = rows(strcmp({rows.scenario_base}, scenarioBase) & strcmp({rows.csi_mode}, 'ESTIMATED'));
    if isempty(rowSet)
        pathOut = '';
        return;
    end

    fig = figure('Color', 'w', 'Visible', 'off', 'Position', [100, 100, 1200, 820]);
    tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
    metricSpecs = { ...
        'BER', 'BER', 'semilogy'; ...
        'BLER', 'BLER', 'semilogy'; ...
        'throughput_bps', 'Effective Throughput (bps)', 'plot'; ...
        'latency_s', 'Latency Proxy (s)', 'plot'};
    styleList = {'-o', '-s', '-d'};

    for imetric = 1:size(metricSpecs, 1)
        ax = nexttile;
        hold(ax, 'on');
        for ipacket = 1:numel(packetOrder)
            row = localFindRow(rowSet, packetOrder{ipacket});
            if isempty(row)
                continue;
            end
            values = row.(metricSpecs{imetric, 1});
            if strcmpi(metricSpecs{imetric, 3}, 'semilogy')
                values = max(values, 1e-7);
                semilogy(ax, row.EbN0s_dB, values, styleList{ipacket}, ...
                    'LineWidth', 1.6, 'MarkerSize', 7);
            else
                plot(ax, row.EbN0s_dB, values, styleList{ipacket}, ...
                    'LineWidth', 1.6, 'MarkerSize', 7);
            end
        end
        grid(ax, 'on');
        xlabel(ax, 'Eb/N0 (dB)');
        ylabel(ax, metricSpecs{imetric, 2});
        title(ax, metricSpecs{imetric, 2});
        if imetric <= 2
            ylim(ax, [1e-5, 1]);
        end
        if imetric == 1
            legend(ax, packetOrder, 'Location', 'best');
        end
    end

    sgtitle(fig, sprintf('%s | Estimated CSI | Packet-Length Tradeoff', scenarioBase));
    pathOut = fullfile(outputDir, sprintf('%s_PACKET_TRADEOFF.png', scenarioBase));
    exportgraphics(fig, pathOut, 'Resolution', 220);
    localExportPdf(fig, pathOut, options.save_pdf);
    close(fig);
end

function pathOut = localGenerateCsiComparisonFigure(rows, scenarioBase, outputDir, options)
    rowSet = rows(strcmp({rows.scenario}, scenarioBase));
    rowSet = rowSet(ismember({rowSet.csi_mode}, {'ESTIMATED', 'IDEAL'}));
    if numel(rowSet) < 2
        pathOut = '';
        return;
    end

    fig = figure('Color', 'w', 'Visible', 'off', 'Position', [100, 100, 1200, 820]);
    tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
    metricSpecs = { ...
        'BER', 'BER', 'semilogy'; ...
        'BLER', 'BLER', 'semilogy'; ...
        'throughput_bps', 'Effective Throughput (bps)', 'plot'; ...
        'nmse', 'Channel NMSE', 'semilogy'};
    styleList = {'-o', '-s'};
    modeOrder = {'ESTIMATED', 'IDEAL'};

    for imetric = 1:size(metricSpecs, 1)
        ax = nexttile;
        hold(ax, 'on');
        for imode = 1:numel(modeOrder)
            row = localFindModeRow(rowSet, modeOrder{imode});
            if isempty(row)
                continue;
            end
            values = row.(metricSpecs{imetric, 1});
            if strcmpi(metricSpecs{imetric, 3}, 'semilogy')
                values = max(values, 1e-7);
                semilogy(ax, row.EbN0s_dB, values, styleList{imode}, ...
                    'LineWidth', 1.6, 'MarkerSize', 7);
            else
                plot(ax, row.EbN0s_dB, values, styleList{imode}, ...
                    'LineWidth', 1.6, 'MarkerSize', 7);
            end
        end
        grid(ax, 'on');
        xlabel(ax, 'Eb/N0 (dB)');
        ylabel(ax, metricSpecs{imetric, 2});
        title(ax, metricSpecs{imetric, 2});
        if imetric <= 2 || strcmp(metricSpecs{imetric, 1}, 'nmse')
            ylim(ax, [1e-5, 1]);
        end
        if imetric == 1
            legend(ax, modeOrder, 'Location', 'best');
        end
    end

    sgtitle(fig, sprintf('%s | LONG Packet | CSI Comparison', scenarioBase));
    pathOut = fullfile(outputDir, sprintf('%s_CSI_COMPARISON.png', scenarioBase));
    exportgraphics(fig, pathOut, 'Resolution', 220);
    localExportPdf(fig, pathOut, options.save_pdf);
    close(fig);
end

function pathList = localGenerateGlobalSummary(rows, outputDir, options)
    packetOrder = {'LONG', 'MEDIUM', 'SHORT'};
    estimatedRows = rows(strcmp({rows.csi_mode}, 'ESTIMATED'));
    metrics = struct('ber', zeros(1, numel(packetOrder)), ...
        'bler', zeros(1, numel(packetOrder)), ...
        'throughput', zeros(1, numel(packetOrder)), ...
        'latency', zeros(1, numel(packetOrder)));

    for ipacket = 1:numel(packetOrder)
        rowSet = estimatedRows(strcmp({estimatedRows.packet_length}, packetOrder{ipacket}));
        if isempty(rowSet)
            continue;
        end
        metrics.ber(ipacket) = median(arrayfun(@(r) r.BER(end), rowSet));
        metrics.bler(ipacket) = median(arrayfun(@(r) r.BLER(end), rowSet));
        metrics.throughput(ipacket) = median(arrayfun(@(r) r.throughput_bps(end), rowSet));
        metrics.latency(ipacket) = median(arrayfun(@(r) r.latency_s(1), rowSet));
    end

    fig = figure('Color', 'w', 'Visible', 'off', 'Position', [100, 100, 1100, 760]);
    tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
    metricNames = {'ber', 'bler', 'throughput', 'latency'};
    yLabels = {'Median BER @ max Eb/N0', 'Median BLER @ max Eb/N0', ...
        'Median Effective Throughput (bps)', 'Median Latency Proxy (s)'};

    for imetric = 1:numel(metricNames)
        ax = nexttile;
        values = metrics.(metricNames{imetric});
        if imetric <= 2
            semilogy(ax, 1:numel(packetOrder), max(values, 1e-7), '-o', ...
                'LineWidth', 1.8, 'MarkerSize', 7);
            ylim(ax, [1e-5, 1]);
        else
            plot(ax, 1:numel(packetOrder), values, '-o', ...
                'LineWidth', 1.8, 'MarkerSize', 7);
        end
        grid(ax, 'on');
        xticks(ax, 1:numel(packetOrder));
        xticklabels(ax, packetOrder);
        xlabel(ax, 'Packet Length');
        ylabel(ax, yLabels{imetric});
        title(ax, yLabels{imetric});
    end

    sgtitle(fig, 'Phase 4 Global Packet-Length Summary');
    pngPath = fullfile(outputDir, 'phase4_global_packet_summary.png');
    exportgraphics(fig, pngPath, 'Resolution', 220);
    localExportPdf(fig, pngPath, options.save_pdf);
    close(fig);
    pathList = {pngPath};
end

function row = localFindRow(rowSet, packetLength)
    idx = find(strcmp({rowSet.packet_length}, packetLength), 1);
    if isempty(idx)
        row = [];
        return;
    end
    row = rowSet(idx);
end

function row = localFindModeRow(rowSet, modeName)
    idx = find(strcmp({rowSet.csi_mode}, modeName), 1);
    if isempty(idx)
        row = [];
        return;
    end
    row = rowSet(idx);
end

function localExportPdf(fig, pngPath, savePdf)
    if ~savePdf
        return;
    end

    pdfPath = strrep(pngPath, '.png', '.pdf');
    exportgraphics(fig, pdfPath, 'ContentType', 'vector');
end
