% TODO: Documentation
%
% Cai Wingfield 2010-05, 2010-08, 2015-03--2015-06
% update by Li Su 3-2012, 11-2012
% updated Fawad 12-2013, 02-2014, 10-2014

import rsa.*
import rsa.util.*
import rsa.par.*
import rsa.meg.*

userOptions = tonotopicMappingOptions();

prints('Starting RSA analysis "%s".', userOptions.analysisName);


%% %%%%%%%%%%%%%%%%%%%%%%%%
prints('Preparing model RDMs...');
%%%%%%%%%%%%%%%%%%%%%%%%%%%

models = directLoad('/imaging/cw04/Neurolex/Lexpro/Analysis_Tonotopy_rerun/old-code/scripts/allmodels_16bins.mat');
models = reconfigure_tonotopy_models(models);

%% %%%%%%%%%%%%%%%%%%%
prints('Preparing masks...');
%%%%%%%%%%%%%%%%%%%%%%

% TODO: Don't enforce use of both hemispheres

usingMasks = ~isempty(userOptions.maskNames);
if usingMasks
    slMasks = MEGMaskPreparation_source(userOptions);
    % For this searchlight analysis, we combine all masks into one
    slMasks = combineVertexMasks_source(slMasks, 'combined_mask', userOptions);  
else
    slMasks = allBrainMask(userOptions);
end


%% Compute some constats
nSubjects = numel(userOptions.subjectNames);
adjacencyMatrices = calculateMeshAdjacency(userOptions.targetResolution, userOptions.sourceSearchlightRadius, userOptions, 'hemis', 'LR');


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%
prints('Starting parallel toolbox...');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if userOptions.flush_Queue
    flushQ();
end

if userOptions.run_in_parallel
    p = initialise_CBU_Queue(userOptions);
end


%% %%%%%%%%%%%%%%%%%%
prints('Loading brain data...');
%%%%%%%%%%%%%%%%%%%%%

[meshPaths, STCMetadatas] = MEGDataPreparation_source( ...
    lexproBetaCorrespondence(), ...
    userOptions, ...
    'mask', slMasks);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
prints('Searchlight Brain RDM Calculation...');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[RDMsPaths, slSTCMetadatas] = MEGSearchlightRDMs_source( ...
    meshPaths, ...
    slMasks, ...
    ...% Assume that both hemis' adjacency matrices are the same so only use one.
    adjacencyMatrices.L, ...
    STCMetadatas, ...
    userOptions);


%% %%%%%
prints('Averaging searchlight RDMs...');
%%%%%%%%

averageRDMPaths = averageSearchlightRDMs(RDMsPaths, userOptions);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
prints('GLM-fitting models to searchlight RDMs...');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

first_model_frame = 5;

[glm_paths, lagSTCMetadatas] = searchlight_dynamicGLM_source( ...
    averageRDMPaths, ...
    models, first_model_frame, ...
    slSTCMetadatas, ...
    userOptions, ...
    'lag', 0);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
prints('Thresholding GLM values...');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
prints('Cleaning up...');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Close the parpool
if userOptions.run_in_parallel
    delete(p);
end

% Sending an email
if userOptions.recieveEmail
    setupInternet();
    setupEmail(userOptions.mailto);
end

prints( ...
    'RSA COMPLETE!');
