function [hEnc, hDec] = CreateLDPCObjects(H_parity, maxIterations)
%CREATELDPCOBJECTS Construct LDPC encoder/decoder objects for this project.

    if nargin < 2 || isempty(maxIterations)
        maxIterations = 20;
    end

    if ~issparse(H_parity)
        H_parity = sparse(H_parity);
    end

    encOutput = evalc('tmpEnc = comm.LDPCEncoder(H_parity);'); %#ok<NASGU>
    decOutput = evalc('tmpDec = comm.LDPCDecoder(H_parity);'); %#ok<NASGU>
    hEnc = tmpEnc;
    hDec = tmpDec;
    hDec.IterationTerminationCondition = 'Maximum iteration count';
    hDec.MaximumIterationCount = maxIterations;
end
