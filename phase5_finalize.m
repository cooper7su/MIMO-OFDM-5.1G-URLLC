function phase5Bundle = phase5_finalize()
%PHASE5_FINALIZE Build Phase 5 publication assets from validated batch runs.

    setup_project_paths();

    projectRoot = fileparts(mfilename('fullpath'));
    batchBase = fullfile(projectRoot, 'results', 'batch_sweeps');
    publicationRoot = fullfile(projectRoot, 'results', 'phase5_publication');
    batchRoots = localResolveBatchRoots(batchBase);

    if ~exist(publicationRoot, 'dir')
        mkdir(publicationRoot);
    end

    [datasetPath, publicationData] = generate_phase5_publication_dataset( ...
        publicationRoot, batchRoots, 'phase5_publication_dataset.mat');
    plotSummary = generate_phase5_publication_plots(datasetPath, fullfile(publicationRoot, 'plots'));
    [auditReportPath, auditData] = audit_phase5_results(publicationRoot, struct( ...
        'batch_roots', {batchRoots}, ...
        'phase4_root', fullfile(batchBase, 'phase4_full_matrix_smoke'), ...
        'phase3_root', fullfile(batchBase, 'phase3_full_matrix_smoke_v2'), ...
        'phase2_root', fullfile(batchBase, 'phase2_rician_smoke_v2'), ...
        'phase2_regression_root', fullfile(batchBase, 'phase4_phase2_regression'), ...
        'report_filename', 'phase5_audit_report.md', ...
        'mat_filename', 'phase5_audit_summary.mat'));
    progressReportPath = generate_phase5_progress_report(publicationRoot, publicationData, ...
        auditData, plotSummary, struct( ...
        'batch_roots', {batchRoots}, ...
        'dataset_path', datasetPath, ...
        'audit_report_path', auditReportPath, ...
        'report_filename', 'phase5_progress_report.md'));

    phase5Bundle = struct();
    phase5Bundle.generated_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    phase5Bundle.publication_dataset_path = datasetPath;
    phase5Bundle.publication_data = publicationData;
    phase5Bundle.plot_summary = plotSummary;
    phase5Bundle.progress_report_path = progressReportPath;
    phase5Bundle.audit_report_path = auditReportPath;
    phase5Bundle.audit_data = auditData;

    save(fullfile(publicationRoot, 'phase5_bundle.mat'), 'phase5Bundle');

    fprintf('Phase 5 publication dataset : %s\n', datasetPath);
    fprintf('Phase 5 progress report     : %s\n', progressReportPath);
    fprintf('Phase 5 audit report        : %s\n', auditReportPath);
    fprintf('Phase 5 plot root           : %s\n', plotSummary.output_dir);
end

function batchRoots = localResolveBatchRoots(batchBase)
    staticRoot = fullfile(batchBase, 'phase4_full_matrix_smoke');
    dynamicCandidates = { ...
        fullfile(batchBase, 'phase5_dynamic_extension_v2'), ...
        fullfile(batchBase, 'phase5_dynamic_extension'), ...
        fullfile(batchBase, 'phase5_dynamic_smoke_v3')};

    batchRoots = {localRequireCompletedBatch(staticRoot), ...
        localSelectExistingRoot(dynamicCandidates)};
end

function selectedRoot = localSelectExistingRoot(candidates)
    selectedRoot = '';
    for icandidate = 1:numel(candidates)
        if exist(candidates{icandidate}, 'dir')
            selectedRoot = localRequireCompletedBatch(candidates{icandidate});
            return;
        end
    end

    error('未找到可用的 Phase 5 动态批次目录。');
end

function batchRoot = localRequireCompletedBatch(batchRoot)
    summaryFile = fullfile(batchRoot, 'batch_summary.mat');
    if ~exist(summaryFile, 'file')
        error('批次目录缺少 batch_summary.mat: %s', batchRoot);
    end

    summaryData = load(summaryFile, 'batchSummary');
    batchSummary = summaryData.batchSummary;
    if ~isfield(batchSummary, 'num_scenarios') || ~isfield(batchSummary, 'num_success') || ...
            ~isfield(batchSummary, 'num_failed') || ...
            batchSummary.num_success ~= batchSummary.num_scenarios || ...
            batchSummary.num_failed ~= 0
        error('批次尚未完成或存在失败场景: %s', batchRoot);
    end
end
