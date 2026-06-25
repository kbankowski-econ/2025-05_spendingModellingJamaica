% PREAMBLE
% Run only the four Jamaica scenarios needed for the Jamaica chart.
close all;
clear all;
clc;

% recalling the paths
utils.call.paths;

runTimer = tic;
timerGuard = onCleanup(@() fprintf('\nrunModelJamaica total execution time: %s (%.0f s)\n', ...
        string(duration(0, 0, toc(runTimer))), toc(runTimer)));

% Cding to a relevant directory
cd(fullfile(project_path, 'models'));

%% Jamaica model list: {name, params, efficiency, shocks}
% These runs use Jamaica macro parameters with Jamaica-specific efficiency gaps.
modelList = {
    'JAM_Model_HumanCapital_epsiig',            'JAM', 'JAM',   {{'epsi_ig',      'const', 0.01,  '1:1000'}}
    'JAM_Model_HumanCapital_epsicge',           'JAM', 'JAM',   {{'epsi_cge',     'const', 0.01,  '1:1000'}}
    'JAM_Model_HumanCapital_epsiigeff30y',      'JAM', 'JAM',   {{'epsi_ig',      'const', 0.01,  '1:1000'}
                                                                 {'epsi_eff',     'ramp',  0.415, '1:60'}}
    'JAM_Model_HumanCapital_epsicgeeff30y',     'JAM', 'JAM',   {{'epsi_cge',     'const', 0.01,  '1:1000'}
                                                                 {'epsi_effge',   'ramp',  0.3665, '1:60'}}
    };

%% run Jamaica models
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

%% Canonicalize only the Jamaica result files.
for iModel = 1:size(modelList, 1)
    utils.subroutines.spawnCanonicalize(modelList{iModel, 1});
end
