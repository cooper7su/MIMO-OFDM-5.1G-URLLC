function [reportPath, auditData] = audit_phase5_results(outputRoot, options)
%AUDIT_PHASE5_RESULTS Audit Phase 5 publication outputs and regressions.

    if nargin < 2
        options = struct();
    end
    if ~isfield(options, 'report_filename') || isempty(options.report_filename)
        options.report_filename = 'phase5_audit_report.md';
    end
    if ~isfield(options, 'mat_filename') || isempty(options.mat_filename)
        options.mat_filename = 'phase5_audit_summary.mat';
    end

    [reportPath, auditData] = audit_phase4_results(outputRoot, options);
end
