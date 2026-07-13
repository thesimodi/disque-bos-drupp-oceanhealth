function output = C_lolik(pm,dt)

% Construct the negative log-likelihood function which is used in the Maximum-Likelihood estimation of Tobit Model.

% pm is a 3x1 vector of parameters, pm = (alpha,eta,log(sigma))
alpha = pm(1);
eta = pm(2);
sig = exp(pm(3)); % pm(3) is the log of standard deviation in a normal distribution of error

% dt is the data used in Nonlinear least squares (20x2 matrix), which consists of
hr = dt(:,1); % goal1
pog = dt(:,2); % price_of_redist

[n,m] = size(dt); lo_lik = 0; h = .00001; k = .00000001;

sigm = max([sig, h]);

for i = 1:n

    % Define the optimal share to goal1 allocated
    mu = ( (pog(i)^((eta-1)/eta)) * ( ((1-alpha)/alpha)^(1/eta) ) + 1 )^(-1);
    
    % Update the value of the log-likelihood function
    
    % log-likelihood function when ith goal1 is 0
    if hr(i) == 0
        x = -mu/sigm;
        lo_lik = lo_lik + log(normcdf(x));

    % log-likelihood function when ith goal1 is 1
    elseif hr(i) == 1
        x = (1-mu)/sigm;
        lo_lik = lo_lik + log(max([k,1-normcdf(x)]));

    % log-likelihood function when 0< hr(i) <1
    else        
        x = ((hr(i) - mu)/sigm)^2;
        lo_lik = lo_lik - 0.5*(log(2*pi) + log(sigm^2) + x);        
    end
    
end

% output is negative log-likelihood function with n observations
output = - lo_lik;
