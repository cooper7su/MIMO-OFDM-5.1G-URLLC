%% ===========================================================
%  TDL-A PDP — 23 Taps (3GPP TR 38.901 Table 7.7.2-1)
%  Clean PPT-ready bar chart (DS scaling; top-K labels only)
% ===========================================================
clear; close all; clc;

%% 1) Desired RMS delay spread
DS_desired_ns = 100;      % 可改：10 / 30 / 100 / 300 / 1000
topK = 6;                 % 只给功率最大的前 K 个抽头做标注（0 = 不标）

%% 2) TDL-A taps (normalized delay & power[dB]) — 3GPP 38.901
tau_norm = [ ...
    0.0000, 0.3819, 0.4025, 0.5868, 0.4610, 0.5375, 0.6708, 0.5750, 0.7618, ...
    1.5375, 1.8978, 2.2242, 2.1718, 2.4942, 2.5119, 3.0582, 4.0810, 4.4579, ...
    4.5695, 4.7966, 5.0066, 5.3043, 9.6586 ];
power_dB = [ ...
   -13.4, 0.0, -2.2, -4.0, -6.0, -8.2, -9.9, -10.5, -7.5, ...
   -15.9, -6.6, -16.7, -12.4, -15.2, -10.8, -11.3, -12.7, -16.2, ...
   -18.3, -18.9, -16.6, -19.9, -29.7 ];
N = numel(tau_norm);

%% 3) Linearize power & scale delays to DS (per 7.7.3)
p = 10.^(power_dB/10);      % 线性功率
p = p / sum(p);             % 归一化到 Σp=1
tau_ns = tau_norm * DS_desired_ns;

% (可选) 相干带宽估计（仅用于标题展示）
Bc_MHz = 1e3 / (5 * DS_desired_ns);

%% 4) Figure (clean style)
fig = figure('Color','w'); fig.Position = [100 100 1000 560]; % 16:9
ax = axes(fig); hold(ax,'on'); box(ax,'on'); grid(ax,'on');
ax.FontName='Arial'; ax.FontSize=12; ax.LineWidth=1.2;
ax.GridAlpha=0.12; ax.YMinorGrid='on'; ax.TickDir='out';
ax.XColor=[0.2 0.2 0.2]; ax.YColor=[0.2 0.2 0.2];

% Colormap
try
    cmap = turbo(N);
catch
    cmap = parula(N);
end

% Bars
x = 1:N; bar_w = 0.62;
b = bar(x, p, 'BarWidth', bar_w, 'FaceColor','flat', ...
    'EdgeColor',[0.6 0.6 0.6], 'LineWidth',1.0);
for i = 1:N, b.CData(i,:) = cmap(i,:); end
b.FaceAlpha = 0.95;

% Axes & title
xticks(x);
xticklabels(arrayfun(@(k) sprintf('\\tau_{%d}', k-1), 1:N, 'UniformOutput', false));
xlabel('\tau_k  (tap index)', 'Interpreter','tex', 'FontSize',14);
ylabel('Power  (linear, normalized)', 'Interpreter','tex', 'FontSize',14);
title(sprintf('TDL-A PDP  (3GPP TR 38.901, 23 taps)   DS = %d ns   (B_c \\approx %.2f MHz)', ...
      DS_desired_ns, Bc_MHz), 'FontWeight','bold','FontSize',16);

ylim([0, max(p)*1.30]); pbaspect([1.6 1 1]);

%% 5) Top-K labels only (use \newline + 'tex' to avoid interpreter warnings)
if topK > 0
    [~, idx_desc] = sort(p, 'descend');
    label_idx = sort(idx_desc(1:min(topK, N)));   % 从左到右标注
    y_off = max(p)*0.035;
    for i = label_idx(:).'
        txt = sprintf('%+.1f dB\\newline%.1f ns', power_dB(i), tau_ns(i));
        text(x(i), p(i) + y_off, txt, ...
            'HorizontalAlignment','center','VerticalAlignment','bottom', ...
            'FontName','Arial','FontSize',10.5,'Color',[0.15 0.15 0.15], ...
            'Interpreter','tex');
    end
end

%% 6) Export PNG (300 dpi)
outdir = fullfile(pwd, 'results', 'figs'); if ~exist(outdir,'dir'), mkdir(outdir); end
outfile = fullfile(outdir, sprintf('PDP_TDLA_DS%dns.png', DS_desired_ns));
try
    exportgraphics(gcf, outfile, 'Resolution', 300, 'BackgroundColor','white');
catch
    print(gcf, outfile, '-dpng', '-r300');
end
fprintf('Figure saved: %s\n', outfile);
