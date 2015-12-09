function y = nanSum(x, dim)

x(isnan(x)) = 0;

if nargin == 1
    y = sum(x);
else
    y = sum(x, dim);
end
