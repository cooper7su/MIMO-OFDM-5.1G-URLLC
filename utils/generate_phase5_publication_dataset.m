function [datasetPath, publicationData] = generate_phase5_publication_dataset(outputRoot, batchRoots, datasetFilename)
%GENERATE_PHASE5_PUBLICATION_DATASET Build one unified Phase 5 publication dataset.

    if nargin < 3 || isempty(datasetFilename)
        datasetFilename = 'phase5_publication_dataset.mat';
    end

    [datasetPath, publicationData] = generate_phase4_publication_dataset( ...
        outputRoot, batchRoots, datasetFilename);
end
