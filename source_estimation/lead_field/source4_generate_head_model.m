clear; clc;

% ##### STEP 4: GENERATE BEM SURFACES AND CREATE LEAD FIELD USING OPENMEEG #####

% ##### SETTINGS #####

% Subject ID
ID = {'001';'002';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};

% Full list of subjects to process
for x = 1:length(ID)
    SubjectNames{x,1} = ['sub',ID{x,1}];
end

% Subject to start
iSubjStart = 1;

% Conditions
con = {'C1';'C2'};
site = {'pfc';'ppc'};
tms = 'tms';
tr = {'T0';'T1'};
u = '_';

% Data path
pathData = 'I:\nmda_tms_eeg\CLEAN_ICA\';

% Electrode path
pathElec = 'I:\nmda_tms_eeg\ELECTRODE_POSITIONS\';

% Brainstorm data path
pathBS = 'F:\brainstorm_db\TMS-EEG_NMDA\data\';

% Brainstorm data path
pathBSanat = 'F:\brainstorm_db\TMS-EEG_NMDA\anat\';

% ##### INITIATE BRAINSTORM #####

% Initiate Brainstorm GUI
if ~brainstorm('status')
    brainstorm nogui
end

% The protocol name has to be a valid folder name (no spaces, no weird characters...)
ProtocolName = 'TMS-EEG_NMDA';

% Get the protocol index
iProtocol = bst_get('Protocol', ProtocolName);
if isempty(iProtocol)
    error(['Unknown protocol: ' ProtocolName]);
end
% Select the current procotol
gui_brainstorm('SetCurrentProtocol', iProtocol);

% ##### RUN SCRIPT #####
for iSubj = iSubjStart:length(SubjectNames)

    % Load sFileEp
    load([pathData,ID{iSubj,1},filesep,'bs_settings.mat']);
    
    % Process: Generate BEM surfaces
    sFiles = bst_process('CallProcess', 'process_generate_bem', sFileEp.(con{1}).(site{1}).(tr{1}), [], ...
        'subjectname', SubjectNames{iSubj}, ...
        'nscalp',      1922, ...
        'nouter',      1922, ...
        'ninner',      1922, ...
        'thickness',   4);

    % Process: Compute head model
    sFiles = bst_process('CallProcess', 'process_headmodel', sFileEp.(con{1}).(site{1}).(tr{1}), [], ...
        'Comment',     '', ...
        'sourcespace', 1, ...  % Cortex surface
        'eeg',         3, ...  % OpenMEEG BEM
        'openmeeg',    struct(...
             'BemFiles',     {{}}, ...
             'BemNames',     {{'Scalp', 'Skull', 'Brain'}}, ...
             'BemCond',      [1, 0.0125, 1], ...
             'BemSelect',    [1, 1, 1], ... %Maybe different from GUI...
             'isAdjoint',    0, ...
             'isAdaptative', 1, ...
             'isSplit',      0, ...
             'SplitLength',  4000));
         
     % Copy the forward model file to the other runs
     sHeadmodel = bst_get('HeadModelForStudy', sFileEp.(con{1}).(site{1}).(tr{1})(1).iStudy);
     for i = 1:length(con)
         for j = 1:length(site)
             for k = 1:length(tr)

                 if i ~=1 || j ~= 1 || k ~= 1
                     DataFile = sFileEp.(con{i}).(site{j}).(tr{k})(1).FileName;
                     [sStudy, iStudy, iData] = bst_get('DataFile', DataFile);
                     db_add(iStudy, sHeadmodel.FileName);
                 end
                 
             end
         end
     end
         
end