function neg_loglik = C_lolik(params, data)
% Negative log-likelihood of the Tobit model, censored at shares of 0 and 1
% params = [alpha, eta, log SD of the error]
% data columns: budget share spent on goal 1, price of redistribution (p2/p1)

alpha = params(1);
eta = params(2);
sd = max(exp(params(3)), 1e-5); % bounded away from zero
share = data(:,1);
price = data(:,2);

% Predicted share to goal 1 (in logs to avoid 0*Inf = NaN at small eta)
mu = 1 ./ (1 + exp(((eta-1)*log(price) + log((1-alpha)/alpha))/eta));

% Log-likelihood of each decision: censored at 0, censored at 1, or interior
at_0 = share == 0;
at_1 = share == 1;
interior = ~at_0 & ~at_1;

loglik = zeros(size(share));
loglik(at_0) = log(normcdf(-mu(at_0)/sd));
loglik(at_1) = log(max(1e-8, normcdf((1-mu(at_1))/sd, 'upper')));
loglik(interior) = -0.5*(log(2*pi) + log(sd^2) + ((share(interior) - mu(interior))/sd).^2);

neg_loglik = -sum(loglik);
