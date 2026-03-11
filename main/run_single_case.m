function result = run_single_case(cfg)
%RUN_SINGLE_CASE Execute one BER/BLER/URLLC scenario defined by cfg.

    rng(cfg.random_seed, 'twister');

    if ~exist(cfg.output_dir, 'dir')
        mkdir(cfg.output_dir);
    end

    csiModes = get_csi_mode_list(cfg);
    numModes = numel(csiModes);
    numEb = numel(cfg.EbN0s_dB);
    modeStats = repmat(localInitModeStats(numEb), 1, numModes);

    for iEb = 1:numEb
        EbN0_dB = cfg.EbN0s_dB(iEb);
        fprintf('Running %s | Eb/N0 = %.1f dB\n', cfg.scenario_tag, EbN0_dB);

        for iframe = 1:cfg.N_frame
            tx_frame = build_transmit_frame(cfg);
            channel_state = run_frame_channel(tx_frame.Frame_transmit, cfg, EbN0_dB);

            for imode = 1:numModes
                rx_frame = process_receive_frame(channel_state, tx_frame, cfg, csiModes{imode});
                modeStats(imode).bitErrors(iEb) = modeStats(imode).bitErrors(iEb) + rx_frame.frameErrors;
                modeStats(imode).totalBits(iEb) = modeStats(imode).totalBits(iEb) + rx_frame.frameBits;
                modeStats(imode).blockErrors(iEb) = modeStats(imode).blockErrors(iEb) + rx_frame.blockErrors;
                modeStats(imode).totalBlocks(iEb) = modeStats(imode).totalBlocks(iEb) + rx_frame.blockCount;
                if isfield(rx_frame.estimation_info, 'nmse') && isfinite(rx_frame.estimation_info.nmse)
                    modeStats(imode).channelNmseSum(iEb) = modeStats(imode).channelNmseSum(iEb) + rx_frame.estimation_info.nmse;
                    modeStats(imode).channelNmseCount(iEb) = modeStats(imode).channelNmseCount(iEb) + 1;
                end
            end
        end
    end

    modeResults = struct();
    plotSeries = repmat(struct('label', '', 'values', []), 1, numModes);
    metricSeries = struct('ber', plotSeries, 'bler', plotSeries, 'throughput', plotSeries);

    for imode = 1:numModes
        modeName = lower(csiModes{imode});
        BER = modeStats(imode).bitErrors ./ max(modeStats(imode).totalBits, 1);
        BLER = modeStats(imode).blockErrors ./ max(modeStats(imode).totalBlocks, 1);
        urlcc = compute_urlcc_metrics(cfg, BLER, ...
            modeStats(imode).blockErrors, modeStats(imode).totalBlocks);
        berMetrics = evaluate_curve_metrics(cfg.EbN0s_dB, BER, cfg.eta_eff);
        avgChannelNmse = modeStats(imode).channelNmseSum ./ max(modeStats(imode).channelNmseCount, 1);
        avgChannelNmse(modeStats(imode).channelNmseCount == 0) = NaN;

        modeResult = struct();
        modeResult.mode = modeName;
        modeResult.EbN0s_dB = cfg.EbN0s_dB;
        modeResult.BER = BER;
        modeResult.BLER = BLER;
        modeResult.bitErrors = modeStats(imode).bitErrors;
        modeResult.totalBits = modeStats(imode).totalBits;
        modeResult.blockErrors = modeStats(imode).blockErrors;
        modeResult.totalBlocks = modeStats(imode).totalBlocks;
        modeResult.packetErrors = modeStats(imode).blockErrors;
        modeResult.totalPackets = modeStats(imode).totalBlocks;
        modeResult.channel_nmse = avgChannelNmse;
        modeResult.ber_metrics = berMetrics;
        modeResult.urlcc = urlcc;
        modeResult.reliability = urlcc.reliability;
        modeResult.reliability_target_met = urlcc.reliability_target_met;
        modeResults.(modeName) = modeResult;

        metricSeries.ber(imode) = struct('label', upper(modeName), 'values', BER);
        metricSeries.bler(imode) = struct('label', upper(modeName), 'values', BLER);
        metricSeries.throughput(imode) = struct('label', upper(modeName), 'values', urlcc.effective_throughput_bps);
    end

    figure_paths = struct();
    figure_paths.ber = save_metric_curve_plot(cfg.EbN0s_dB, metricSeries.ber, cfg, 'BER', ...
        'BER', 'semilogy', [1e-5, 1]);
    figure_paths.bler = save_metric_curve_plot(cfg.EbN0s_dB, metricSeries.bler, cfg, 'BLER', ...
        'BLER', 'semilogy', [1e-5, 1]);
    figure_paths.throughput = save_metric_curve_plot(cfg.EbN0s_dB, metricSeries.throughput, cfg, ...
        'THROUGHPUT', 'Effective Throughput (bps)', 'plot', []);
    figure_paths.summary = save_publication_summary_plot(cfg.EbN0s_dB, metricSeries, cfg);

    primaryMode = cfg.primary_csi_mode;
    primaryResult = modeResults.(primaryMode);

    result = struct();
    result.scenario_tag = cfg.scenario_tag;
    result.EbN0s_dB = cfg.EbN0s_dB;
    result.csi_modes = csiModes;
    result.primary_csi_mode = primaryMode;
    result.packet_length_mode = cfg.packet_length_mode;
    result.packet_length_label = cfg.packet_length_label;
    result.packet_length_bits = cfg.packet_length_bits;
    result.packet_length_symbols = cfg.packet_length_symbols;
    result.mode_results = modeResults;
    result.comparison = localBuildComparison(modeResults);
    result.BER = primaryResult.BER;
    result.BLER = primaryResult.BLER;
    result.bitErrors = primaryResult.bitErrors;
    result.totalBits = primaryResult.totalBits;
    result.blockErrors = primaryResult.blockErrors;
    result.totalBlocks = primaryResult.totalBlocks;
    result.packetErrors = primaryResult.packetErrors;
    result.totalPackets = primaryResult.totalPackets;
    result.metrics = primaryResult.ber_metrics;
    result.urlcc = primaryResult.urlcc;
    result.reliability = primaryResult.reliability;
    result.reliability_target_met = primaryResult.reliability_target_met;
    result.effectiveThroughput_bps = primaryResult.urlcc.effective_throughput_bps;
    result.nominalThroughput_bps = primaryResult.urlcc.nominal_throughput_bps;
    result.latencyProxy_s = primaryResult.urlcc.latency_proxy_s;
    result.channel_nmse = primaryResult.channel_nmse;
    result.figure_paths = figure_paths;
    result.figure_path = figure_paths.ber;
    result.cfg = cfg;
end

function stats = localInitModeStats(numEb)
    stats = struct();
    stats.bitErrors = zeros(1, numEb);
    stats.totalBits = zeros(1, numEb);
    stats.blockErrors = zeros(1, numEb);
    stats.totalBlocks = zeros(1, numEb);
    stats.channelNmseSum = zeros(1, numEb);
    stats.channelNmseCount = zeros(1, numEb);
end

function comparison = localBuildComparison(modeResults)
    comparison = struct();
    if isfield(modeResults, 'estimated') && isfield(modeResults, 'ideal')
        comparison.ber_delta = modeResults.estimated.BER - modeResults.ideal.BER;
        comparison.bler_delta = modeResults.estimated.BLER - modeResults.ideal.BLER;
        comparison.throughput_delta_bps = ...
            modeResults.estimated.urlcc.effective_throughput_bps - ...
            modeResults.ideal.urlcc.effective_throughput_bps;
    end
end
