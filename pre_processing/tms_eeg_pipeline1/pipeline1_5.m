% scriptForBatch.m
% This script here makes it so that we can save some stuff for the batch script

% wes = getenv('number');
% wes = str2num(wes);
% wes = 1;

%###### STEP 5: INTERPOLATE TMS PULSE, DOWNSAMPLE, FILTER, CUT ENDS OF TRIALS, FINAL BASELINE CORRECTION #####

ID = {'001';'002';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'};
site = {'pfc';'ppc'};
tms = 'tms';
tr = {'t0';'t1'};
u = '_';

suf = 'ep_bc_ica1_clean_sound_ica2_clean_sspsir';

% SET UP PATHS FOR DATA
pathData = '/projects/kg98/Nigel/TMS-EEG_NMDA/data/';
pathIn = '/projects/kg98/Nigel/TMS-EEG_NMDA/data/step4/';
pathOut = '/projects/kg98/Nigel/TMS-EEG_NMDA/data/final/';
pathLfData = '/projects/kg98/Nigel/TMS-EEG_NMDA/data/ANAT/';

%Makes a path folder
if ~isequal(exist(pathOut, 'dir'),7)
    mkdir(pathOut);
end


%% PREP FOR PARFOR LOOP
for a = 1:size(ID,1) % Loop over participants
    for c = 1:size(con,1) % Loop over conditions
        
        %Makes a subject folder
        if ~isequal(exist([pathOut,ID{a,1}], 'dir'),7)
            mkdir(pathOut,ID{a,1});
        end
        
        %Makes a condition folder
        if ~isequal(exist([pathOut,ID{a,1},filesep,con{c,1}], 'dir'),7)
            mkdir([pathOut,ID{a,1},filesep],con{c,1});
        end
        
        for b = 1:size(site,1) % Loop over open/closed
            for x = 1:size(tr,1)  % Loop over time points
                
                tempFilePathIn{a,c,b,x} = [pathIn ID{a,1} filesep con{c,1} filesep];
                tempFileNameIn{a,c,b,x} = [ID{a,1} u con{c,1} u tms u site{b,1} u tr{x,1} u suf '.set'];
                tempFilePathOut{a,c,b,x} = [pathOut ID{a,1} filesep con{c,1} filesep];
                tempFileNameOut{a,c,b,x} = [ID{a,1} u con{c,1} u tms u site{b,1} u tr{x,1} u 'FINAL.set'];;
                templfPathIn{a,c,b,x} = [pathLfData,ID{a,1},filesep];
                
            end
        end
    end
end

% Reshape name structures for loop
filePathIn = reshape(tempFilePathIn,1,[]);
fileNameIn = reshape(tempFileNameIn,1,[]);
filePathOut = reshape(tempFilePathOut,1,[]);
fileNameOut = reshape(tempFileNameOut,1,[]);
lfPathIn = reshape(templfPathIn,1,[]);

% Load all channel file
load([pathData,'allChan.mat']);

%% RUN PIPELINE

startid = '001';
startcon = 'C1';
startsite = 'pfc';
starttr = 't0';
startName = [startid u startcon u tms u startsite u starttr u suf '.set'];
[~,startN] = ismember(startName,fileNameIn);

for wes = startN:length(fileNameOut)
    
    tic;
    restCleaningStep5(filePathIn{wes},fileNameIn{wes},filePathOut{wes},fileNameOut{wes});
    timeOut = round(toc);
    fprintf('%d of %d complete. Time = %d s\n',wes,length(fileNameOut),round(timeOut,1));
    
end


%% FUNCTION FOR PARFOR LOOP

function restCleaningStep5(filePathIn,fileNameIn,filePathOut,fileNameOut)
    
    % Load EEG data
    EEG = pop_loadset('filename', fileNameIn, 'filepath', filePathIn);
    
    % Cut and interpolate removed data
    EEG = tesa_removedata( EEG, [-2,6], [], {'R128'} );
    EEG = tesa_interpdata( EEG, 'cubic', [5,5] );
    
    % Downsample
    EEG = pop_resample( EEG, 1000);
    
    % Band pass and stop filter
    EEG = tesa_filtbutter( EEG, [], 100, 4, 'lowpass' );
    EEG = tesa_filtbutter( EEG, 48, 52, 4, 'bandstop' );
    
    % Cut the ends of the signal
    EEG = pop_select(EEG, 'time', [-1, 1]);
    
    % Final baseline correction
    EEG = pop_rmbase( EEG, [-500  -5]);

    % Save data
    EEG = pop_saveset( EEG, 'filename', fileNameOut, 'filepath',filePathOut);   
    
end

