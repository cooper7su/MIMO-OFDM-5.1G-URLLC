function figure_path = save_publication_summary_plot(EbN0s_dB, metricSeries, cfg)
%SAVE_PUBLICATION_SUMMARY_PLOT Export a compact BER/BLER/throughput summary.

    figure_visibility = 'off';
    if isfield(cfg, 'show_figures') && cfg.show_figures
        figure_visibility = 'on';
    end

    fig = figure('Color', 'w', 'Visible', figure_visibility, 'Position', [100, 100, 1200, 420]);
    styleList = {'-o', '-s', '-d', '-^', '-v'};
    metricNames = {'ber', 'bler', 'throughput'};
    yLabels = {'BER', 'BLER', 'Effective Throughput (bps)'};
    plotTypes = {'semilogy', 'semilogy', 'plot'};

    for imetric = 1:numel(metricNames)
        ax = subplot(1, 3, imetric, 'Parent', fig);
        hold(ax, 'on');
        seriesList = metricSeries.(metricNames{imetric});
        for iseries = 1:numel(seriesList)
            thisStyle = styleList{mod(iseries - 1, numel(styleList)) + 1};
            plotValues = seriesList(iseries).values;
            if strcmpi(plotTypes{imetric}, 'semilogy')
                plotValues = max(plotValues, 1e-7);
                semilogy(ax, EbN0s_dB, plotValues, thisStyle, ...
                    'LineWidth', 1.5, 'MarkerSize', 6);
                ylim(ax, [1e-5, 1]);
            else
                plot(ax, EbN0s_dB, plotValues, thisStyle, ...
                    'LineWidth', 1.5, 'MarkerSize', 6);
            end
        end
        grid(ax, 'on');
        xlabel(ax, 'Eb/N0 (dB)');
        ylabel(ax, yLabels{imetric});
        title(ax, upper(metricNames{imetric}));
        if imetric == 1
            legend(ax, {seriesList.label}, 'Location', 'best');
        end
    end

    sgtitle(fig, sprintf('%s | %s | Publication Summary', ...
        cfg.scenario_tag, localGetPacketLabel(cfg)));
    plot_output_dir = localGetPlotDir(cfg);
    figure_path = fullfile(plot_output_dir, sprintf('%s_SUMMARY.png', cfg.scenario_tag));
    exportgraphics(fig, figure_path, 'Resolution', 220);
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
