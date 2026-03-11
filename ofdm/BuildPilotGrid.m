function [pilotGrid, pilotInfo] = BuildPilotGrid(cfg)
%BUILDPILOTGRID Create the deterministic pilot grid used by the receiver.

    pilotGrid = complex(zeros(cfg.N_subcarrier, cfg.N_symbol, cfg.N_Tx));
    pilotAmplitude = cfg.pilot_amplitude;

    if cfg.enable_pilot_estimation && cfg.N_Tx > 1
        if cfg.N_symbol < cfg.N_Tx
            error('Pilot-based estimation requires N_symbol >= N_Tx.');
        end

        orthAmplitude = pilotAmplitude * sqrt(cfg.stbc.num_streams);
        for isym = 1:cfg.N_symbol
            activeTx = mod(isym - 1, cfg.N_Tx) + 1;
            pilotGrid(cfg.index_pilot, isym, activeTx) = orthAmplitude;
        end
        pilotPattern = 'orthogonal_time_tx';
    else
        for itx = 1:cfg.N_Tx
            pilotGrid(cfg.index_pilot, :, itx) = pilotAmplitude;
        end
        pilotPattern = 'legacy_full_tx';
    end

    pilotInfo = struct();
    pilotInfo.pattern = pilotPattern;
    pilotInfo.amplitude = pilotAmplitude;
    pilotInfo.index_pilot = cfg.index_pilot(:);
    pilotInfo.active_mask = abs(pilotGrid) > 0;
end
