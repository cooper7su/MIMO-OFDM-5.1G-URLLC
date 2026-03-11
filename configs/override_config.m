function cfg = override_config(cfg, varargin)
%OVERRIDE_CONFIG Clone and re-finalize a scenario configuration.

    if ~localHasExplicitCsiOverride(varargin{:})
        staleFields = {'csi_modes', 'primary_csi_mode'};
        for ifield = 1:numel(staleFields)
            if isfield(cfg, staleFields{ifield})
                cfg = rmfield(cfg, staleFields{ifield});
            end
        end
    end

    cfg = apply_config_overrides(cfg, varargin{:});
    cfg = finalize_config(cfg);
end

function tf = localHasExplicitCsiOverride(varargin)
    tf = false;
    if nargin < 1 || isempty(varargin)
        return;
    end

    if numel(varargin) == 1 && isstruct(varargin{1})
        overrideFields = fieldnames(varargin{1});
        tf = any(strcmp(overrideFields, 'csi_modes')) || ...
            any(strcmp(overrideFields, 'primary_csi_mode'));
        return;
    end

    if mod(numel(varargin), 2) ~= 0
        return;
    end

    for iarg = 1:2:numel(varargin)
        fieldName = varargin{iarg};
        if ischar(fieldName) || isstring(fieldName)
            fieldName = char(fieldName);
            if strcmp(fieldName, 'csi_modes') || strcmp(fieldName, 'primary_csi_mode')
                tf = true;
                return;
            end
        end
    end
end
