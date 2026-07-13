clear

% This code requires the "fminsearchbnd" app/add-on installed
% This code also requires the parallelization toolkit

% Define the working directory (relative)
if isempty(mfilename('fullpath'))
    % Scripts
    fullpath = matlab.desktop.editor.getActiveFilename();
else
    % Function
    fullpath = mfilename('fullpath');
end

currentFolder = fileparts(fullpath);
parentFolder = fileparts(fileparts(currentFolder));
cd(parentFolder);

% Define the working directory (absolute)
% if getenv('USERNAME') == "disqu"
%     cd 'C:/Users/disqu/Dokumente/Coding Lokal/bodimo-analysis';
% end

% Specify this path to call functions in this directory
addpath('4_Code/Matlab_OHI/')

% Artefact (previously used to Loop over pilot & online data)
for sample=["online"]
    % Import the otree data
    if sample == "pilot"
        Data = readtable('1_Data/2_processed/Data_decision_task.csv');
    elseif sample == "online"
        Data = readtable('1_Data/2_processed/Data_decision_task_online.csv');
    end
    
    % Remove unnecessary variables / Rename variable names / Rearrange columns
    if sample == "pilot"
        Data = removevars(Data,{'session', 'round', 'id', 'session_subject_id', 'subject_label', 'to_goal1_max', 'to_goal2_max', 'price_goal1', 'price_goal2', 'price_ratio', 'goal1_code', 'goal2_code'});
        Data = renamevars(Data,["to_goal1_p","to_goal2_p","block_number", "subject"], ...
                           ["incshare_goal1","incshare_goal2","task_number", "participant_code"]);
        Data = Data(:,{'participant_code', 'incshare_goal1', 'incshare_goal2', 'price_of_redist', 'task_number', 'goal_pair', 'to_goal1', 'to_goal2'});
    elseif sample == "online"
        Data = removevars(Data,{'id', 'participant_label', 'session_label', 'session_code', 'goal1_code', 'goal2_code', 'to_goal1_max', 'to_goal2_max', 'price_goal1', 'price_goal2', 'price_ratio', 'goal1_code', 'goal2_code'});
        Data = renamevars(Data,["to_goal1_p","to_goal2_p","block_number"], ...
                           ["incshare_goal1","incshare_goal2","task_number"]);
        Data = Data(:,{'participant_code', 'incshare_goal1', 'incshare_goal2', 'price_of_redist', 'task_number', 'goal_pair', 'to_goal1', 'to_goal2'});
    end

    % Get all unique (subject) ids
    subject_ids = unique(table2array(Data(:,1)));
    num_participants = length(subject_ids(:,1));
    
    % Define some options for lsqnonlin() and fminsearch()
    opts = optimset('Display','off');
    options = optimset('Display','off','MaxFunEvals',1e+6);
    
    % Determine how many rounds should be evaluated
    if sample == "pilot"
        round_options = {2, 3, 4, 5, 10, 15, 20, 25};
    elseif sample == "online"
        round_options = {20};
    end
    
    for r=1:length(round_options)
        rounds = round_options{r};
    
        % Initate an empty 3D results cell array (this improves performance and is
        % needed for parallelization)
        Results = cell(5, num_participants, 10);

        % Loop over each subject and task to estimate the CES parameters
        parfor current_subject = 1:num_participants
            % Initiates error margin and counter
            h = .00001;
            % counter = 0;

            % Obtain and show subject id
            id = subject_ids(current_subject);
            % counter = counter ++ 1;
            display(current_subject)
    
            % Obtain number of subject tasks (some had 5, some had 3)
            subject_tasks = unique(table2array(Data(ismember(Data.participant_code, id), "task_number")));

            for current_block = 1:5 % Loop over all tasks of a subject
                % Skip last two blocks if participant only had 3 tasks
                if current_block > max(subject_tasks)
                    continue
                end

                task_name = Data(ismember(Data.participant_code, id) & Data.task_number == current_block, "goal_pair");
                task_name = task_name{1, 1};
    
                % Obtain the choices of subject i in task t
                Data_it = Data(ismember(Data.participant_code, id) & Data.task_number == current_block, :);
    
                % Adjust for number of rounds to be evaluated
                Data_it = Data_it(1:rounds,:);
    
                % For the estimation, we filter for the data of a given subject id
                % and select two variables (goal1, price_of_redist).
                subdt = table2array([Data_it(:,2), Data_it(:,4)]);

                % Calculate share of points given to goal 1; used to
                % screenout participants later on
                subdt(:,3) = Data_it{:,7} ./ (Data_it{:,7} + Data_it{:,8});
    
                % In order to find an appropriate initial value for Tobit estimation,
                % we first use nonlinear least squares estimation.
                opts = optimset('Display','off');
                options = optimset('Display','off','MaxFunEvals',1e+6);
    
                x0 = [0.5,1];
    
                % Run NLLS regression (with parameter bounds)
                [x,res] = lsqnonlin(@B_nlregf,x0,[0 0],[1 inf],opts,subdt,rounds);
    
                % Log standard deviation of the normal distributed error, needed in MLE
                sg2 = log(h+(res/(rounds-2)));
    
                % The NLLS estimated initial values for the parameters are served as a starting point
                % in the search of Maximum-Likelihood estimation with Nelder-Meade Simplex Method.
                pm0 = [x,sg2];
    
                % Flag subjects with average share of income given to one goal over 98% (rho not meaningful) 
                if mean(subdt(:,3)) > 0.98 | mean(subdt(:,3)) < 0.02
                    unipref = 1;
                else
                    unipref = 0;
                end

                % Run ML estimation with parameter bounds
                [pm,fval] = fminsearchbnd(@C_lolik,pm0,[0 0 -inf],[1 inf inf],options,subdt);

                % Store the results
                alpha = pm(1); % Alpha parameter
                eta = pm(2); % Substitutability parameter
                sigma = 1/eta; % Elasticity of substitution
                rho = 1-eta; % Elasticity of complementarity

                % Write the results to the corresponding row of the Results array
                Results(current_block, current_subject, :) = {id, current_block, task_name, rho, sigma, eta, alpha, x(2), x(1), unipref};
            end
        end
        
        % Convert 3D results cell array back to 2D cell array
        Results_2D = reshape(Results, [], 10);
        
        % Remove empty rows (-> last two blocks for participants that only
        % saw 3)
        Results_2D = Results_2D(~all(cellfun(@isempty, Results_2D), 2), :);

        % Convert Results to a table with variable names
        Results_Array = array2table(Results_2D);
        Results_Array.Properties.VariableNames = {'participant_code','task_number','task_name','rho','sigma','eta', 'alpha', 'nllsq_eta', 'nllsq_alpha', 'unipref'};

        % Create a decision-level results table to analyze fit of predicted
        % vs. observed allocation shares

        % Create copy of both tables and wrangle data
        Data_dl = Data;
        Results_dl = Results_Array;

        Data_dl.task_number2 = string(Data_dl.task_number);
        Results_dl.task_number2 = string(Results_dl.task_number);
        Data_dl.participant_code = string(Data_dl.participant_code);
        Results_dl.participant_code = string(Results_dl.participant_code);

        Results_decision_level = join(Data_dl, Results_dl, 'Keys', {'participant_code', 'task_number2'});

        Results_decision_level.alpha = cell2mat(Results_decision_level.alpha);
        Results_decision_level.eta = cell2mat(Results_decision_level.eta);
        
        % Calculate predicted values and errors
        Results_decision_level.mu = (Results_decision_level.alpha./(1-Results_decision_level.alpha)).^(1./Results_decision_level.eta) ./ (Results_decision_level.price_of_redist.^(-(1-Results_decision_level.eta)./Results_decision_level.eta) + (Results_decision_level.alpha./(1-Results_decision_level.alpha)).^(1./Results_decision_level.eta) );
        Results_decision_level.e = Results_decision_level.incshare_goal1 - Results_decision_level.mu;
        
        Results_decision_level = removevars(Results_decision_level,{'task_number2', 'task_number_Results_dl'});
        Results_decision_level = renamevars(Results_decision_level,'task_number_Data_dl', 'task_number');

        % Export the results
        if sample == "pilot"
            if rounds == 25
                writetable(Results_Array, '1_Data/2_processed/Matlab_Results_OHI.csv')
                writetable(Results_decision_level, '1_Data/2_processed/Matlab_Results_OHI_decision_level.csv')
            else
                writetable(Results_Array, ['1_Data/2_processed/Matlab_Results_OHI_', num2str(rounds), '_rounds.csv'])
                writetable(Results_decision_level, ['1_Data/2_processed/Matlab_Results_OHI_', num2str(rounds), '_rounds_decision_level.csv'])
            end
        elseif sample == "online"
            writetable(Results_Array, '1_Data/2_processed/Matlab_Results_OHI_online.csv')
            writetable(Results_decision_level, '1_Data/2_processed/Matlab_Results_OHI_online_decision_level.csv')
        end    
    end
end