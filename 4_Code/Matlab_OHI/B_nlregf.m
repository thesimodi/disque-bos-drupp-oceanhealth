function residuals = B_nlregf(params, data)
% Residuals of the CES demand function, minimized in the NLLS estimation
% params = [alpha, eta]
% data columns: budget share spent on goal 1, price of redistribution (p2/p1)

alpha = params(1);
eta = params(2);
share = data(:,1);
price = data(:,2);

% Predicted share to goal 1 (in logs to avoid 0*Inf = NaN at small eta)
predicted_share = 1 ./ (1 + exp(((eta-1)*log(price) + log((1-alpha)/alpha))/eta));
residuals = share - predicted_share;
