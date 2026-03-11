function urlcc = compute_urlcc_metrics(cfg, BLER, blockErrors, totalBlocks)
%COMPUTE_URLCC_METRICS Compute frame-level URLLC metrics from cfg and BLER.

    if nargin < 3 || isempty(blockErrors)
        blockErrors = zeros(size(BLER));
    end
    if nargin < 4 || isempty(totalBlocks)
        totalBlocks = ones(size(BLER));
    end

    blockErrors = reshape(blockErrors, size(BLER));
    totalBlocks = max(reshape(totalBlocks, size(BLER)), 1);

    confidenceLevel = localGetConfidenceLevel(cfg);
    tailFloor = localGetTailFloor(cfg);

    nominalThroughput = repmat(cfg.nominal_throughput_bps, size(BLER));
    nominalPayloadThroughput = repmat(cfg.nominal_payload_throughput_bps, size(BLER));
    effectiveThroughput = cfg.payload_bits_per_frame .* (1 - BLER) ./ cfg.latency_proxy_s;
    effectivePayloadThroughput = cfg.payload_bits_per_frame .* (1 - BLER) ./ cfg.frame_duration_s;
    packetSuccessProbability = 1 - BLER;

    thresholds = cfg.bler_target_thresholds(:);
    targetMet = false(numel(thresholds), numel(BLER));
    targetConfidence = zeros(numel(thresholds), numel(BLER));
    tailRisk = zeros(numel(thresholds), numel(BLER));
    for ithreshold = 1:numel(thresholds)
        targetMet(ithreshold, :) = BLER <= thresholds(ithreshold);
        targetConfidence(ithreshold, :) = betainc( ...
            thresholds(ithreshold), blockErrors + 1, totalBlocks - blockErrors + 1);
        tailRisk(ithreshold, :) = max(1 - targetConfidence(ithreshold, :), tailFloor);
    end

    [blerConfidenceInterval, reliabilityConfidenceInterval] = ...
        localComputeConfidenceIntervals(blockErrors, totalBlocks, confidenceLevel);

    urlcc = struct();
    urlcc.packet_length_mode = cfg.packet_length_mode;
    urlcc.packet_length_label = cfg.packet_length_label;
    urlcc.packet_symbol_count = cfg.packet_length_symbols;
    urlcc.payload_bits_per_packet = cfg.payload_bits_per_packet;
    urlcc.payload_bits_per_frame = cfg.payload_bits_per_frame;
    urlcc.frame_duration_s = cfg.frame_duration_s;
    urlcc.latency_proxy_s = repmat(cfg.latency_proxy_s, size(BLER));
    urlcc.latency_physical_s = repmat(cfg.frame_duration_s, size(BLER));
    urlcc.pilot_overhead_time_s = repmat(cfg.pilot_overhead_time_s, size(BLER));
    urlcc.pilot_overhead_ratio = cfg.pilot_overhead_ratio;
    urlcc.coding_overhead_ratio = cfg.coding_overhead_ratio;
    urlcc.block_errors = blockErrors;
    urlcc.total_blocks = totalBlocks;
    urlcc.packet_success_probability = packetSuccessProbability;
    urlcc.reliability = packetSuccessProbability;
    urlcc.bler_target_thresholds = thresholds;
    urlcc.reliability_target_met = targetMet;
    urlcc.reliability_target_confidence = targetConfidence;
    urlcc.reliability_tail_probability = tailRisk;
    urlcc.bler_confidence_level = confidenceLevel;
    urlcc.bler_confidence_interval = blerConfidenceInterval;
    urlcc.reliability_confidence_interval = reliabilityConfidenceInterval;
    urlcc.nominal_throughput_bps = nominalThroughput;
    urlcc.nominal_payload_throughput_bps = nominalPayloadThroughput;
    urlcc.effective_throughput_bps = effectiveThroughput;
    urlcc.effective_payload_throughput_bps = effectivePayloadThroughput;
end

function confidenceLevel = localGetConfidenceLevel(cfg)
    confidenceLevel = 0.95;
    if isfield(cfg, 'bler_confidence_level') && ~isempty(cfg.bler_confidence_level)
        confidenceLevel = cfg.bler_confidence_level;
    end
end

function tailFloor = localGetTailFloor(cfg)
    tailFloor = 1e-9;
    if isfield(cfg, 'tail_probability_floor') && ~isempty(cfg.tail_probability_floor)
        tailFloor = cfg.tail_probability_floor;
    end
end

function [blerInterval, reliabilityInterval] = localComputeConfidenceIntervals(blockErrors, totalBlocks, confidenceLevel)
    alpha = 1 - confidenceLevel;
    lower = betaincinv(alpha / 2, blockErrors + 0.5, totalBlocks - blockErrors + 0.5);
    upper = betaincinv(1 - alpha / 2, blockErrors + 0.5, totalBlocks - blockErrors + 0.5);

    invalidMask = totalBlocks < 1;
    lower(invalidMask) = NaN;
    upper(invalidMask) = NaN;

    blerInterval = [lower; upper];
    reliabilityInterval = [1 - upper; 1 - lower];
end
