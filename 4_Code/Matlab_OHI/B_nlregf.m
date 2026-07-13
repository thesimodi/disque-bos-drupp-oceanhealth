function output = B_nlregf(x,dt,rounds)

% Construct the residuals in each observed sample, which is used to compute
% the sum of squared residuals in the Nonlinear Least Squares Estimation.

% We use:
% x(1) = alpha
% x(2) = eta

% dt is the data used in NLLS (20x2 matrix), which consists of
% dt(:, 1) = goal1
% dt(:, 2) = price_of_redist.

out = zeros(rounds,1);

for i = 1:rounds
    
    % Demand function formula
    out(i) = dt(i,1) - ((dt(i,2)^((x(2)-1)/x(2))) * ((1-x(1))/x(1))^(1/x(2)) + 1)^(-1);
    
end

output = out;
