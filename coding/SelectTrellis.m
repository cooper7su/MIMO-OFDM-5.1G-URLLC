function trellis = SelectTrellis(code_rate)
% 根据码率智能生成网格结构
% 输入:
%   code_rate - 编码速率(1/2, 1/3, 3/4)
% 输出:
%   trellis - 对应的网格结构
% 公共参数
constraint_length = 7; % 统一约束长度
base_polynomials = [171, 133]; % 基础生成多项式(八进制)
% 根据码率动态生成多项式
switch code_rate
    case {1/2,2/3}
        polynomials = base_polynomials(1:2);
    case 1/3
        polynomials = [base_polynomials, 165]; % 添加第三个多项式
    case 3/4
        polynomials = base_polynomials; % 使用基础多项式+打孔
    otherwise
        error('不支持的码率: %.2f', code_rate);
end
% 统一生成网格结构
trellis = poly2trellis(constraint_length, polynomials);
% 特殊码率提示
if code_rate == 3/4
    warning('3/4码率需配合打孔模式使用，请确保编码/解码使用相同的打孔模式');
end
end