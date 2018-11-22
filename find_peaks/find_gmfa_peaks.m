% ##### FIND PEAKS IN GMFA #####

% This script calcuates the global mean field amplitude (GMFA) for baseline
% TEPs, averages GMFAs across the two baselines, and then automatically 
% finds peaks present in the GMFA. 
% The script also repeats this analysis for the Fz electrode following PFC 
% stimulation to define the missing two peaks.
% Inputs are the grand average structure of the EEG data generated by 
% FieldTrip

% Author: Nigel Rogasch, Monash University

clear; close all; clc;

% Experimental variables
ID = {'001';'002';'004';'005';'006';'007';'008';'009';'010';'011';'012';'013';'014';'015'};
con = {'C1';'C2'}; % two experimental sessions seperated by at least a week
site = {'pfc';'ppc'}; % two different stimulation sites
tr = {'T0';'T1'}; % two different time points within a day - t0 = baseline, t1 = following drug/placebo

% Data set to use
dataSet = 'CLEAN_ICA'; % 'CLEAN_ICA' | 'CLEAN_SOUND'

pathIn = ['I:\nmda_tms_eeg\',dataSet,'\'];

% Time window to search for peaks (15-300 ms)
peakWin = [15,300];

% Number of +/- ms for peak
peakDef = [5,15];
peakDefWin = [10,100;101,300];

% Load GrandAverage file
load([pathIn,'grandAverage_N',num2str(length(ID)),'.mat']);

% Calculate GMFA for each individual and condition and average across baseline conditions
for cidx = 1:size(con,1)
    for sidx = 1:size(site,1)
               
        % Calculate GMFA for each individual
        for gidx = 1:size(grandAverage.C1.pfc.T0.individual,1)
            gmfa.(con{cidx,1}).(site{sidx})(gidx,:,:) = std(grandAverage.(con{cidx,1}).(site{sidx}).T0.individual(gidx,:,:),[],2);
        end
                
    end
end

% Time vector (ms)
time = grandAverage.C1.pfc.T0.time*1000;

% Calculate average
for idx = 1:size(site,1)
    
    % Concatenate C1 and C2 baseline conditions
    gmfaAll.(site{idx,1}) = cat(1,gmfa.C1.(site{idx}),gmfa.C2.(site{idx}));
    
    % Average across conditions
    gmfaAve.(site{idx,1}) = mean(gmfaAll.(site{idx,1}),1);
    
end
    
% Automatically find GMFA peaks between 10-300 ms
% Peak is defined as a point which is larger in amplitude that the point
% +/- 5 ms.

for sidx = 1:size(site,1)

    % Find time points to define time series
    [val,tpW(1,1)] = min(abs(time-peakWin(1,1)));
    [val,tpW(1,2)] = min(abs(time-peakWin(1,2)));

    % Extract time series
    tseries = gmfaAve.(site{sidx,1});

    % Set -2 to 10 ms to 0;
    [~,tp1] = min(abs(-2-time));
    [~,tp2] = min(abs(10-time));
    tseries(1,tp1:tp2) = 0;

    latHold = [];
    num = 1;
    for b = tpW(1,1):tpW(1,2)
        
        ztime = time(1,b);
        
        % Find +/- windows
        tPlus = [];
        tMinus = [];
        if time(1,b) <= peakDefWin(1,2)
            for c = 1:peakDef(1,1)
                tPlus(c,1) = tseries(1,b) - tseries(1,b+c);
                tMinus(c,1) = tseries(1,b) - tseries(1,b-c);
            end
        else
            for c = 1:peakDef(1,2)
                tPlus(c,1) = tseries(1,b) - tseries(1,b+c);
                tMinus(c,1) = tseries(1,b) - tseries(1,b-c);
            end
        end

        % Find time points greater than 0
        tPlusLog = tPlus > 0;
        tMinusLog = tMinus > 0;
        
        testOut(1,b-(tpW(1,1)-1)) = size(tPlus,1) + size(tMinus,1);

        % Assess if central time point is greater than surrounding points
        if  time(1,b) <= peakDefWin(1,2)
            if sum(tPlusLog) + sum(tMinusLog) == peakDef(1,1)*2
                latHold(num,1) = b;
                num = num+1;
            end
        else
            if sum(tPlusLog) + sum(tMinusLog) == peakDef(1,2)*2
                latHold(num,1) = b;
                num = num+1;
            end
        end
    end
    
    % Calculate latencies
    latencies.(site{sidx,1}) = time(1,latHold);
end

% % Remove first peak from ppc as the actual peak did not fall within the
% % time range
% latencies.ppc(:,1) = [];

% Calculate latency ranges
% Ranges are calcualted by taking half or the difference between subsequent
% peaks. First and last points are set to the time window of interest.
for sidx = 1:size(site,1)
    difference.(site{sidx,1}) = diff(latencies.(site{sidx,1}));
    
    for idx = 1:length(latencies.(site{sidx,1}))
        if idx == 1
            latRange.(site{sidx,1})(idx,1) = peakWin(1,1);
            latRange.(site{sidx,1})(idx,2) = latencies.(site{sidx,1})(1,idx)+ceil(round(difference.(site{sidx,1})(1,idx))./2);
        elseif idx == length(latencies.(site{sidx,1}))
            latRange.(site{sidx,1})(idx,1) = latencies.(site{sidx,1})(1,idx)-floor(round(difference.(site{sidx,1})(1,idx-1))./2);
            latRange.(site{sidx,1})(idx,2) = peakWin(1,2);
        else
            latRange.(site{sidx,1})(idx,1) = latencies.(site{sidx,1})(1,idx)-floor(round(difference.(site{sidx,1})(1,idx-1))./2);
            latRange.(site{sidx,1})(idx,2) = latencies.(site{sidx,1})(1,idx)+ceil(round(difference.(site{sidx,1})(1,idx))./2);
        end
    end
end

% Plot gmfa with peaks and time ranges shaded
for idx = 1:size(site,1)
    figure;
    plot(time,gmfaAve.(site{idx,1}),'k','linewidth',2); hold on;
    
    CM = parula(size(latRange.(site{idx,1}),1));
    for pidx = 1:size(latRange.(site{idx,1}),1)
        aidx = time>latRange.(site{idx,1})(pidx,1) & time<latRange.(site{idx,1})(pidx,2);
        H = area(time(aidx),gmfaAve.(site{idx,1})(aidx));
        set(H(1),'FaceColor',CM(pidx,:));
    end
    
    title(site{idx,1});
    set(gca,'xlim',[-200,500]);
    
end

% Plot FZ for PFC
baseMean = (grandAverage.C1.pfc.T0.individual+grandAverage.C2.pfc.T0.individual)./2;
dataMean = squeeze(mean(baseMean,1));
figure;
plot(time,dataMean(17,:),'k');

peakWinOrig = peakWin;
siteOrig = site;
gmfaOrig = gmfaAve;

peakWin = [25,75];
site = {'pfc'};
gmfaAve.pfc = dataMean(17,:);
for sidx = 1:size(site,1)

    % Find time points to define time series
    [val,tpW(1,1)] = min(abs(time-peakWin(1,1)));
    [val,tpW(1,2)] = min(abs(time-peakWin(1,2)));

    % Extract time series
    tseries = gmfaAve.(site{sidx,1});

    % Set -2 to 10 ms to 0;
    [~,tp1] = min(abs(-2-time));
    [~,tp2] = min(abs(10-time));
    tseries(1,tp1:tp2) = 0;

    latHold = [];
    num = 1;
    for b = tpW(1,1):tpW(1,2)
        
        ztime = time(1,b);
        
        % Find +/- windows
        tPlus = [];
        tMinus = [];
        if time(1,b) <= peakDefWin(1,2)
            for c = 1:peakDef(1,1)
                tPlus(c,1) = tseries(1,b) - tseries(1,b+c);
                tMinus(c,1) = tseries(1,b) - tseries(1,b-c);
            end
        else
            for c = 1:peakDef(1,2)
                tPlus(c,1) = tseries(1,b) - tseries(1,b+c);
                tMinus(c,1) = tseries(1,b) - tseries(1,b-c);
            end
        end

        % Find time points greater than 0
        tPlusLog = tPlus > 0;
        tMinusLog = tMinus > 0;
        
        testOut(1,b-(tpW(1,1)-1)) = size(tPlus,1) + size(tMinus,1);

        % Assess if central time point is greater than surrounding points
        if  time(1,b) <= peakDefWin(1,2)
            if sum(tPlusLog) + sum(tMinusLog) == peakDef(1,1)*2
                latHold(num,1) = b;
                num = num+1;
            end
        else
            if sum(tPlusLog) + sum(tMinusLog) == peakDef(1,2)*2
                latHold(num,1) = b;
                num = num+1;
            end
        end
    end
    
    % Calculate latencies
    latenciesTemp = time(1,latHold);
end

latencies.pfc = [latencies.pfc,latenciesTemp];
latencies.pfc = sort(latencies.pfc);

% Re-Calculate latency ranges and plot GMFAs
% Ranges are calcualted by taking half or the difference between subsequent
% peaks. First and last points are set to the time window of interest.
peakWin = peakWinOrig;
site = siteOrig;
gmfaAve = gmfaOrig;
for sidx = 1:size(site,1)
    difference.(site{sidx,1}) = diff(latencies.(site{sidx,1}));
    
    for idx = 1:length(latencies.(site{sidx,1}))
        if idx == 1
            latRange.(site{sidx,1})(idx,1) = peakWin(1,1);
            latRange.(site{sidx,1})(idx,2) = latencies.(site{sidx,1})(1,idx)+ceil(round(difference.(site{sidx,1})(1,idx))./2);
        elseif idx == length(latencies.(site{sidx,1}))
            latRange.(site{sidx,1})(idx,1) = latencies.(site{sidx,1})(1,idx)-floor(round(difference.(site{sidx,1})(1,idx-1))./2);
            latRange.(site{sidx,1})(idx,2) = peakWin(1,2);
        else
            latRange.(site{sidx,1})(idx,1) = latencies.(site{sidx,1})(1,idx)-floor(round(difference.(site{sidx,1})(1,idx-1))./2);
            latRange.(site{sidx,1})(idx,2) = latencies.(site{sidx,1})(1,idx)+ceil(round(difference.(site{sidx,1})(1,idx))./2);
        end
    end
end

% Plot gmfa with peaks and time ranges shaded
for idx = 1:size(site,1)
    figure;
    plot(time,gmfaAve.(site{idx,1}),'k','linewidth',2); hold on;
    
    CM = parula(size(latRange.(site{idx,1}),1));
    for pidx = 1:size(latRange.(site{idx,1}),1)
        aidx = time>latRange.(site{idx,1})(pidx,1) & time<latRange.(site{idx,1})(pidx,2);
        H = area(time(aidx),gmfaAve.(site{idx,1})(aidx));
        set(H(1),'FaceColor',CM(pidx,:));
    end
    
    title(site{idx,1});
    set(gca,'xlim',[-200,500]);
    
end

% Save latency ranges
save([pathIn,'peak_latency_ranges.mat'],'latencies','latRange');