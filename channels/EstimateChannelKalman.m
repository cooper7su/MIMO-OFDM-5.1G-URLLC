function [H_est, estimationInfo] = EstimateChannelKalman(Frame_receive, pilotGrid, cfg, noise_var, H_ideal)
%ESTIMATECHANNELKALMAN Estimate the physical MIMO channel using Kalman tracking.

    if nargin < 4
        noise_var = 0;
    end
    if nargin < 5
        H_ideal = [];
    end

    [H_est, estimationInfo] = EstimateChannelFromPilots( ...
        Frame_receive, pilotGrid, cfg, 'KALMAN', noise_var, H_ideal);
end
