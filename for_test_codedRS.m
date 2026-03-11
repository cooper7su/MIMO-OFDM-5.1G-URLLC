% 兼容旧组件测试入口。
project_root = fileparts(mfilename('fullpath'));
addpath(project_root);
setup_project_paths();
result = run_rs_codec_sanity();
disp(['无噪声BER: ', num2str(result.ber)]);
