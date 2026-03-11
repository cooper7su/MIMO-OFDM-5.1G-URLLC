function [datasetPath, publicationData] = generate_publication_dataset(batchRoot, datasetFilename)
%GENERATE_PUBLICATION_DATASET Aggregate one batch run into a publication-ready MAT file.

    if nargin < 2 || isempty(datasetFilename)
        datasetFilename = 'phase4_publication_dataset.mat';
    end

    [rows, batchSummary] = collect_publication_rows(batchRoot);

    publicationData = struct();
    publicationData.batchSummary = batchSummary;
    publicationData.rows = rows;
    publicationData.generated_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    publicationData.num_rows = numel(rows);
    publicationData.csi_modes = unique({rows.csi_mode});

    datasetPath = fullfile(batchRoot, datasetFilename);
    save(datasetPath, 'publicationData');
end
