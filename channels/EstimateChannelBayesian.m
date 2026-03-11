function [H_est, estimationInfo] = EstimateChannelBayesian(Frame_receive, pilotGrid, cfg, noise_var, H_ideal)
%ESTIMATECHANNELBAYESIAN Alias of Kalman-style Bayesian tracking for dynamic channels.

    if nargin < 4
        noise_var = 0;
    end
    if nargin < 5
        H_ideal = [];
    end

    [H_est, estimationInfo] = EstimateChannelFromPilots( ...
        Frame_receive, pilotGrid, cfg, 'BAYESIAN', noise_var, H_ideal);
end
