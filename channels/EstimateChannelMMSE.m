function [H_est, estimationInfo] = EstimateChannelMMSE(Frame_receive, pilotGrid, cfg, noise_var, H_ideal)
%ESTIMATECHANNELMMSE Estimate the physical MIMO channel using an MMSE prior.

    if nargin < 4
        noise_var = 0;
    end
    if nargin < 5
        H_ideal = [];
    end

    [H_est, estimationInfo] = EstimateChannelFromPilots( ...
        Frame_receive, pilotGrid, cfg, 'MMSE', noise_var, H_ideal);
end
