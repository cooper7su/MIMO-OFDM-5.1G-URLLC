function figure_path = save_metric_curve_plot(EbN0s_dB, seriesList, cfg, metricName, yLabel, plotType, yLimits)
%SAVE_METRIC_CURVE_PLOT Export one metric curve with one or more CSI modes.

    figure_visibility = 'off';
    if isfield(cfg, 'show_figures') && cfg.show_figures
        figure_visibility = 'on';
    end

    fig = figure('Color', 'w', 'Visible', figure_visibility);
    ax = axes(fig);
    hold(ax, 'on');
    styleList = {'-o', '-s', '-d', '-^', '-v'};

    for iseries = 1:numel(seriesList)
        thisStyle = styleList{mod(iseries - 1, numel(styleList)) + 1};
        plotValues = seriesList(iseries).values;
        if strcmpi(plotType, 'semilogy')
            plotValues = max(plotValues, 1e-7);
            semilogy(ax, EbN0s_dB, plotValues, thisStyle, ...
                'LineWidth', 1.5, 'MarkerSize', 7);
        else
            plot(ax, EbN0s_dB, plotValues, thisStyle, ...
                'LineWidth', 1.5, 'MarkerSize', 7);
        end
    end

    grid(ax, 'on');
    xlabel(ax, 'Eb/N0 (dB)');
    ylabel(ax, yLabel);
    title(ax, sprintf('%s | %s | %s', ...
        cfg.scenario_tag, upper(metricName), localGetPacketLabel(cfg)));
    legend(ax, {seriesList.label}, 'Location', 'best');
    if ~isempty(yLimits)
        ylim(ax, yLimits);
    end

    plot_output_dir = localGetPlotDir(cfg);
    plot_filename = sprintf('%s_%s.png', cfg.scenario_tag, upper(metricName));
    figure_path = fullfile(plot_output_dir, plot_filename);
    exportgraphics(fig, figure_path, 'Resolution', 200);
    localExportPdf(fig, figure_path, cfg);
    close(fig);
end

function packetLabel = localGetPacketLabel(cfg)
    packetLabel = 'LONG';
    if isfield(cfg, 'packet_length_label') && ~isempty(cfg.packet_length_label)
        packetLabel = cfg.packet_length_label;
    end
end

function plot_output_dir = localGetPlotDir(cfg)
    plot_output_dir = cfg.output_dir;
    if isfield(cfg, 'plot_output_dir') && ~isempty(cfg.plot_output_dir)
        plot_output_dir = cfg.plot_output_dir;
    end
    if ~exist(plot_output_dir, 'dir')
        mkdir(plot_output_dir);
    end
end

function localExportPdf(fig, pngPath, cfg)
    if ~isfield(cfg, 'save_pdf_figures') || ~cfg.save_pdf_figures
        return;
    end

    pdfPath = strrep(pngPath, '.png', '.pdf');
    exportgraphics(fig, pdfPath, 'ContentType', 'vector');
end
