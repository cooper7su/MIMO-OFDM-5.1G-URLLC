function cfgSaved = make_serializable_cfg(cfg)
%MAKE_SERIALIZABLE_CFG Remove runtime-only objects before saving config.

    cfgSaved = cfg;
    transientFields = {'hEnc', 'hDec'};
    removable = transientFields(isfield(cfgSaved, transientFields));
    if ~isempty(removable)
        cfgSaved = rmfield(cfgSaved, removable);
    end
end
