function cfg = apply_config_overrides(cfg, varargin)
%APPLY_CONFIG_OVERRIDES Apply struct or name/value overrides to cfg.

    if nargin < 2 || isempty(varargin)
        return;
    end

    if numel(varargin) == 1 && isstruct(varargin{1})
        override_struct = varargin{1};
        override_fields = fieldnames(override_struct);
        for ifield = 1:numel(override_fields)
            cfg.(override_fields{ifield}) = override_struct.(override_fields{ifield});
        end
        return;
    end

    if mod(numel(varargin), 2) ~= 0
        error('配置覆盖参数必须是结构体或成对的名称/值参数。');
    end

    for iarg = 1:2:numel(varargin)
        cfg.(varargin{iarg}) = varargin{iarg + 1};
    end
end
