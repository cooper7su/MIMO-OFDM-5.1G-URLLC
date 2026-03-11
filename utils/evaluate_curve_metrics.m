function metrics = evaluate_curve_metrics(EbN0s_dB, BER, eta_eff)
%EVALUATE_CURVE_METRICS Summarize the BER curve for reporting.

    thresholds = [1e-2, 1e-3, 1e-4];
    threshold_labels = {'1e-2', '1e-3', '1e-4'};
    reqSNR = nan(size(thresholds));

    for i = 1:numel(thresholds)
        reqSNR(i) = snr_at_ber(EbN0s_dB, BER, thresholds(i));
    end

    BER_clip = max(BER, 1e-12);
    score = 10 * eta_eff;
    if isfinite(reqSNR(1)), score = score + max(0, 25 - 1.25 * reqSNR(1)); end
    if isfinite(reqSNR(2)), score = score + max(0, 35 - 1.50 * reqSNR(2)); end
    if isfinite(reqSNR(3)), score = score + max(0, 30 - 2.00 * reqSNR(3)); end
    if any(~isfinite(reqSNR))
        score = min(score, 60 - 10 * sum(~isfinite(reqSNR)));
    end

    metrics = struct();
    metrics.thresholds = thresholds;
    metrics.threshold_labels = threshold_labels;
    metrics.reqSNR = reqSNR;
    if numel(EbN0s_dB) >= 2
        metrics.AUC = trapz(EbN0s_dB, log10(BER_clip));
    else
        metrics.AUC = 0;
    end
    metrics.meanBER = mean(BER);
    metrics.score = max(0, min(100, score));
end
