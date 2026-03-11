% 兼容旧入口。主入口已重构为 main_run.m。
project_root = fileparts(mfilename('fullpath'));
addpath(project_root);
main_run();
