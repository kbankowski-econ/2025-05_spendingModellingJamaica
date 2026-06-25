% PREAMBLE
% cleaning evenrything
close all;
clear all;
clc;

% recalling the paths
utils.call.paths;

% start the overall execution timer; the guard reports elapsed time on
% normal completion and on error/exit
runTimer = tic;
timerGuard = onCleanup(@() fprintf('\nrunModel total execution time: %s (%.0f s)\n', ...
        string(duration(0, 0, toc(runTimer))), toc(runTimer)));

% Cding to a relevant directory
cd(fullfile(project_path, 'models'));

%% gaps for the calibration
% +---------+------------------------------+----------------------------------------------------+
% |         |             AEs              |                       EMDEs                        |
% +---------+------------------------------+----------------------------------------------------+
% | INF     | 0.35                         | (0.37 + 0.46) / 2 = 0.415                          |
% | HLT/EDU | (0.28 + 0.31) / 2 = 0.295    | ((0.30 + 0.29) / 2 + (0.34 + 0.35) / 2) / 2 = 0.320 |
% | RND     | 0.41                         | -                                                  |
% +---------+------------------------------+----------------------------------------------------+

%% model list: {name, params, efficiency, shocks}
% The params entry names a parameter set ('AE', 'EM' or 'JAM') and the efficiency
% entry an efficiency-gap set ('AE', 'EMnorm', 'EMlow' or 'JAM'). The model is
% preprocessed with -DparamFile="<params>_parameters.macro" and
% -DeffFile="<efficiency>_efficiency.macro", which the shared template
% includes after parameters_common.macro, so each macro file holds only
% its specific values.
% Each shocks entry is a cell of {var, kind, value, periods} specs that is
% written to <name>.shockValues (the sole content of the model's shocks
% block, selected via -DshockFile), so the rows are fully self-contained
% and order-independent.
% The per-model <name>.mod and <name>_steadystate.m files are copies of
% models/modelTemplate.mod and models/modelTemplate_steadystate.m made by
% the loop below; the copies are tracked but always regenerate
% byte-identical, so the templates are the source of truth.
%   kind 'const'  - constant value over the periods range (quarters)
%   kind 'ramp'   - linear increase from 0 to value over '1:N', then held
%                   constant through period 1000
%   kind 'custom' - explicit values vector, periods written verbatim
% An optional 5th element sets the sprintf format of the written values
% (default '%g'); 'roundtrip' writes the shortest decimal that parses back
% to the exact double, where the historical files carried full precision.
% The post-simulation commands (solver plus display-only multiplier
% reporting) are identical for all models and live in the shared
% models/postSimul.mod.
%
% Jamaica case deck (docs/2026-06_Jamaica-case): this repo carries only the
% models the deck plots -- the four Jamaica scenarios using JAM parameters
% and JAM efficiency gaps, plus the six EM comparators used in the EM
% baseline charts. The full 48-model list lives in the parent
% 2025-05_spendingModelling repo.

modelList = {
    'EM_Model_HumanCapital_epsiig',             'EM', 'EMnorm', {{'epsi_ig',      'const', 0.01,  '1:1000'}}
    'EM_Model_HumanCapital_epsicge',            'EM', 'EMnorm', {{'epsi_cge',     'const', 0.01,  '1:1000'}}
    'EM_Model_HumanCapital_epsiigeff30y',       'EM', 'EMnorm', {{'epsi_ig',      'const', 0.01,  '1:1000'}
                                                                 {'epsi_eff',     'ramp',  0.415, '1:60'}}
    'EM_Model_HumanCapital_epsiigeff25y',       'EM', 'EMnorm', {{'epsi_ig',      'const', 0.01,  '1:1000'}
                                                                 {'epsi_eff',     'ramp',  0.415, '1:100'}}
    'EM_Model_HumanCapital_epsicgeeff30y',      'EM', 'EMnorm', {{'epsi_cge',     'const', 0.01,  '1:1000'}
                                                                 {'epsi_effge',   'ramp',  0.320, '1:60'}}
    'EM_Model_HumanCapital_epsicgeeff25y',      'EM', 'EMnorm', {{'epsi_cge',     'const', 0.01,  '1:1000'}
                                                                 {'epsi_effge',   'ramp',  0.320, '1:100'}}
    'JAM_Model_HumanCapital_epsiig',            'JAM', 'JAM',   {{'epsi_ig',      'const', 0.01,  '1:1000'}}
    'JAM_Model_HumanCapital_epsicge',           'JAM', 'JAM',   {{'epsi_cge',     'const', 0.01,  '1:1000'}}
    'JAM_Model_HumanCapital_epsiigeff30y',      'JAM', 'JAM',   {{'epsi_ig',      'const', 0.01,  '1:1000'}
                                                                 {'epsi_eff',     'ramp',  0.415, '1:60'}}
    'JAM_Model_HumanCapital_epsicgeeff30y',     'JAM', 'JAM',   {{'epsi_cge',     'const', 0.01,  '1:1000'}
                                                                 {'epsi_effge',   'ramp',  0.3665, '1:60'}}
    };

%% run all models
for iModel = 1:size(modelList, 1)
    thisModel  = modelList{iModel, 1};
    thisParams = modelList{iModel, 2};
    thisEff    = modelList{iModel, 3};
    thisShocks = modelList{iModel, 4};

    utils.subroutines.generateShocksFile([thisModel '.shockValues'], thisShocks);
    copyfile('modelTemplate.mod', [thisModel '.mod']);
    copyfile('modelTemplate_steadystate.m', [thisModel '_steadystate.m']);

    dynare([thisModel '.mod'], 'savemacro', 'json=compute', ...
        sprintf('-DparamFile="%s_parameters.macro"', thisParams), ...
        sprintf('-DeffFile="%s_efficiency.macro"', thisEff), ...
        sprintf('-DshockFile="%s.shockValues"', thisModel));
end

%% Canonicalize all results in a clean child MATLAB process.
% Must be a separate process, not a call in this session: with Dynare
% loaded, save() writes nondeterministic function-handle context into the
% MAT subsystem and the bytes differ run-to-run even for identical data.
% See canonicalizeResults.m.
utils.subroutines.spawnCanonicalize();
