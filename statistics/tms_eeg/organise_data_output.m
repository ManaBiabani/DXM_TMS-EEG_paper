clear; close all; clc;

% N = 14
ID = {'001';'002';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};
site = {'pfc';'ppc'};
tms = 'tms';
tr = {'t0';'t1'};
trAlt = {'T0';'T1'};
u = '_';

% Data set to use
dataSet = 'CLEAN_SOUND2'; % 'CLEAN_ICA1' | 'CLEAN_SOUND2'
dataFilt = ''; % '' for 1-100 Hz, '_2-45Hz' for 2-45 Hz

% Set paths
% Return which computer is running
currentComp = getenv('computername');

% Select path based on computer
if strcmp(currentComp,'CHEWBACCA')
    % Location of 'sound_final' file
    pathIn = ['I:\nmda_tms_eeg\',dataSet,'\'];
else
    % Location of 'sound_final' file
    pathIn = ['D:\nmda_tms_eeg\',dataSet,'\'];
end

% Load GrandAverage file
load([pathIn,'grandAverage',dataFilt,'_N',num2str(length(ID)),'.mat']);

% Load data and create data matrix equivalent to SOUND output
for a = 1:size(con,1)
    for b = 1:size(site,1)
        for c = 1:size(tr,1)         
            for d = 1:size(ID,1)
                id = ['S',ID{d,1}];
                if strcmp(dataSet,'CLEAN_ICA1')
                    dataIn = grandAverage.(con{a,1}).(site{b,1}).(trAlt{c,1}).individual(d,:,:);
                else
                    dataIn = grandAverage.(con{a,1}).(site{b,1}).(tr{c,1}).individual(d,:,:);
                end
                data_FINAL.(id).(con{a,1}).(site{b,1}).(tr{c,1}) = squeeze(dataIn(1,:,:));
            end
                
        end
    end
end

if strcmp(dataSet,'CLEAN_ICA1')
    time = grandAverage.(con{a,1}).(site{b,1}).(trAlt{c,1}).time*1000;
    saveName = 'ica_final';
elseif strcmp(dataSet,'CLEAN_SOUND2')
    time = grandAverage.(con{a,1}).(site{b,1}).(tr{c,1}).time*1000;
    saveName = 'sound_final';
end

save([pathIn,saveName],'data_FINAL','time');