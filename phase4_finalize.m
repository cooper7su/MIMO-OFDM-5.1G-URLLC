function phase4Bundle = phase4_finalize()
%PHASE4_FINALIZE Rebuild Phase 4 datasets, publication plots, and audit reports.

    setup_project_paths();

    projectRoot = fileparts(mfilename('fullpath'));
    batchBase = fullfile(projectRoot, 'results', 'batch_sweeps');
    publicationRoot = fullfile(projectRoot, 'results', 'phase4_publication');
    batchRoots = { ...
        fullfile(batchBase, 'phase4_full_matrix_smoke'), ...
        fullfile(batchBase, 'phase4_full_matrix_medium'), ...
        fullfile(batchBase, 'phase4_full_matrix_short'), ...
        fullfile(batchBase, 'phase4_phase2_regression')};

    for ibatch = 1:numel(batchRoots)
        generate_publication_dataset(batchRoots{ibatch});
    end

    [datasetPath, publicationData] = generate_phase4_publication_dataset(publicationRoot, batchRoots);
    plotSummary = generate_phase4_publication_plots(datasetPath, fullfile(publicationRoot, 'plots'));
    [auditReportPath, auditData] = audit_phase4_results(publicationRoot);

    phase4Bundle = struct();
    phase4Bundle.generated_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    phase4Bundle.publication_dataset_path = datasetPath;
    phase4Bundle.publication_data = publicationData;
    phase4Bundle.plot_summary = plotSummary;
    phase4Bundle.audit_report_path = auditReportPath;
    phase4Bundle.audit_data = auditData;

    save(fullfile(publicationRoot, 'phase4_bundle.mat'), 'phase4Bundle');

    fprintf('Phase 4 publication dataset : %s\n', datasetPath);
    fprintf('Phase 4 audit report        : %s\n', auditReportPath);
    fprintf('Phase 4 plot root           : %s\n', plotSummary.output_dir);
end
