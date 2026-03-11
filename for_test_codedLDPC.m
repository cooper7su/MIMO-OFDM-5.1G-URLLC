% 兼容旧组件测试入口。
project_root = fileparts(mfilename('fullpath'));
addpath(project_root);
setup_project_paths();
cfg = default_config();
result = run_ldpc_codec_sanity(cfg);

disp('=== 无噪声测试结果 ===');
disp(['整体BER: ', num2str(result.ber_total)]);
disp(['编码部分BER: ', num2str(result.ber_coded)]);

if result.passed
    disp('LDPC编解码无噪声测试通过！');
else
    error('测试失败，请检查编码/解码逻辑。');
end
