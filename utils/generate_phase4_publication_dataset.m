function [datasetPath, publicationData] = generate_phase4_publication_dataset(outputRoot, batchRoots, datasetFilename)
%GENERATE_PHASE4_PUBLICATION_DATASET Build one unified Phase 4 publication dataset.

    if nargin < 1 || isempty(outputRoot)
        projectRoot = fileparts(fileparts(mfilename('fullpath')));
        outputRoot = fullfile(projectRoot, 'results', 'phase4_publication');
    end
    if nargin < 2 || isempty(batchRoots)
        batchRoots = localDefaultBatchRoots();
    end
    if nargin < 3 || isempty(datasetFilename)
        datasetFilename = 'publication_dataset.mat';
    end

    if ~exist(outputRoot, 'dir')
        mkdir(outputRoot);
    end

    rowsCell = cell(1, numel(batchRoots));
    batchSummaries = cell(1, numel(batchRoots));
    batchInfo = repmat(struct('name', '', 'root', '', 'num_rows', 0, 'num_scenarios', 0), 1, numel(batchRoots));
    seenKeys = containers.Map('KeyType', 'char', 'ValueType', 'double');
    rowList = {};

    for ibatch = 1:numel(batchRoots)
        [rows, batchSummary] = collect_publication_rows(batchRoots{ibatch});
        rowsCell{ibatch} = rows;
        batchSummaries{ibatch} = batchSummary;
        batchInfo(ibatch).name = batchSummary.sweep_name;
        batchInfo(ibatch).root = batchRoots{ibatch};
        batchInfo(ibatch).num_rows = numel(rows);
        batchInfo(ibatch).num_scenarios = batchSummary.num_scenarios;

        for irow = 1:numel(rows)
            dedupeKey = sprintf('%s|%s', rows(irow).scenario, rows(irow).csi_mode);
            if ~isKey(seenKeys, dedupeKey)
                seenKeys(dedupeKey) = numel(rowList) + 1;
                rowList{end + 1} = rows(irow); %#ok<AGROW>
            end
        end
    end

    publicationData = struct();
    publicationData.generated_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    publicationData.output_root = outputRoot;
    publicationData.batch_roots = batchRoots;
    publicationData.batch_info = batchInfo;
    publicationData.batch_summaries = batchSummaries;
    if isempty(rowList)
        publicationData.rows = repmat(localEmptyPublicationRow(), 0, 1);
        publicationData.num_rows = 0;
        publicationData.csi_modes = {};
        publicationData.packet_lengths = {};
    else
        publicationData.rows = [rowList{:}];
        publicationData.num_rows = numel(publicationData.rows);
        publicationData.csi_modes = unique({publicationData.rows.csi_mode});
        publicationData.packet_lengths = unique({publicationData.rows.packet_length});
    end

    datasetPath = fullfile(outputRoot, datasetFilename);
    save(datasetPath, 'publicationData');
end

function batchRoots = localDefaultBatchRoots()
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    batchBase = fullfile(projectRoot, 'results', 'batch_sweeps');
    batchRoots = { ...
        fullfile(batchBase, 'phase4_full_matrix_smoke'), ...
        fullfile(batchBase, 'phase4_phase2_regression')};
end

function row = localEmptyPublicationRow()
    row = struct();
end
