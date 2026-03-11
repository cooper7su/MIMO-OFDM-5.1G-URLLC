function [Frame_pilot, pilotGrid, pilotInfo] = AddPilot(Frame_STBC, varargin)
%ADDPILOT Write deterministic pilots onto the configured pilot subcarriers.

    if nargin == 2 && isstruct(varargin{1})
        cfg = varargin{1};
        [pilotGrid, pilotInfo] = BuildPilotGrid(cfg);
    elseif nargin >= 4
        index_pilot = varargin{1};
        N_Tx = varargin{3};
        pilotGrid = complex(zeros(size(Frame_STBC)));
        for iant = 1:N_Tx
            pilotGrid(index_pilot, :, iant) = 1;
        end
        pilotInfo = struct('pattern', 'legacy_full_tx', 'index_pilot', index_pilot(:));
    else
        error('AddPilot输入参数不正确。');
    end

    Frame_pilot = Frame_STBC;
    activeMask = abs(pilotGrid) > 0;
    Frame_pilot(activeMask) = pilotGrid(activeMask);
end
