function csiModes = get_csi_mode_list(cfg)
%GET_CSI_MODE_LIST Resolve which CSI modes should be executed.

    if isfield(cfg, 'csi_modes') && ~isempty(cfg.csi_modes)
        csiModes = cfg.csi_modes;
    elseif isfield(cfg, 'enable_pilot_estimation') && cfg.enable_pilot_estimation
        if isfield(cfg, 'compare_csi_with_ideal') && cfg.compare_csi_with_ideal
            csiModes = {'estimated', 'ideal'};
        else
            csiModes = {'estimated'};
        end
    else
        csiModes = {'ideal'};
    end

    if ischar(csiModes) || isstring(csiModes)
        csiModes = cellstr(csiModes);
    end

    csiModes = lower(csiModes(:).');
end
