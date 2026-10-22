%% CES estimation of goal weights (alpha) and substitutability (eta)
% Fits the CES demand function to the allocation decisions of each participant
% and block: NLLS for starting values, then Tobit maximum likelihood.
% Requires the Optimization Toolbox, the Parallel Computing Toolbox, and
% fminsearchbnd (MATLAB File Exchange).

clear

%% Set working directory to project root
script_path = mfilename('fullpath');
if isempty(script_path) % when run section by section
    script_path = matlab.desktop.editor.getActiveFilename();
end
cd(fileparts(fileparts(fileparts(script_path))))
addpath('4_Code/Matlab_OHI/')

%% Load decision data
Data = readtable('1_Data/2_processed/Data_decision_task_online.csv');
Data = renamevars(Data, ["to_goal1_p", "block_number"], ["incshare_goal1", "task_number"]);

participant_ids = unique(Data.participant_code);
n_participants = numel(participant_ids);

%% Optimizer settings
% MaxIter raised from the default (200 x number of parameters) so all blocks converge
nlls_options = optimset('Display', 'off');
ml_options = optimset('Display', 'off', 'MaxFunEvals', 1e6, 'MaxIter', 1e5);

%% Estimate CES parameters per participant and block
Results = cell(n_participants, 1);
n_nonconverged = 0;

parfor i = 1:n_participants
    fprintf('Participant %d of %d\n', i, n_participants)
    id = participant_ids{i};
    Data_i = Data(strcmp(Data.participant_code, id), :);
    n_blocks = max(Data_i.task_number);
    rows = cell(n_blocks, 10);

    for block = 1:n_blocks
        Data_ib = Data_i(Data_i.task_number == block, :);
        n_rounds = height(Data_ib);

        % Columns: budget share spent on goal 1, price of redistribution (p2/p1)
        block_data = [Data_ib.incshare_goal1, Data_ib.price_of_redist];

        % NLLS estimation for starting values (parameters: alpha, eta)
        [nlls_params, ssr] = lsqnonlin(@(params) B_nlregf(params, block_data), ...
            [0.5, 1], [0 0], [1 inf], nlls_options);
        log_sd = 0.5*log(1e-5 + ssr/(n_rounds-2)); % log SD of the NLLS residuals

        % Tobit ML estimation (parameters: alpha, eta, log SD of the error)
        [ml_params, ~, exitflag] = fminsearchbnd(@(params) C_lolik(params, block_data), ...
            [nlls_params, log_sd], [0 0 -inf], [1 inf inf], ml_options);
        n_nonconverged = n_nonconverged + (exitflag ~= 1);

        alpha = ml_params(1);
        eta = ml_params(2); % elasticity of complementarity
        sigma = 1/eta;      % elasticity of substitution
        rho = 1 - eta;      % CES exponent

        % Flag blocks with on average more than 98% of the budget spent on one goal
        mean_share = mean(block_data(:,1));
        unipref = double(mean_share > 0.98 || mean_share < 0.02);

        rows(block, :) = {id, block, Data_ib.goal_pair{1}, rho, sigma, eta, alpha, ...
            nlls_params(2), nlls_params(1), unipref};
    end
    Results{i} = rows;
end

if n_nonconverged > 0
    warning('ML estimation did not converge for %d blocks.', n_nonconverged)
end

%% Export results
Results = cell2table(vertcat(Results{:}), 'VariableNames', ...
    {'participant_code', 'task_number', 'task_name', 'rho', 'sigma', 'eta', ...
     'alpha', 'nllsq_eta', 'nllsq_alpha', 'unipref'});
writetable(Results, '1_Data/2_processed/Matlab_Results_OHI_online.csv')
