% ##### PLOT ELECTRODE EXAMPLES OF TEP CHANGES WITH DRUGS #####

% This script plots single electrodes showing changes in TEPs following
% dextromethorphan and placebo.
% Inputs are the grand average structure of the EEG data generated by 
% FieldTrip.

% Author: Nigel Rogasch, Monash University

clear; close all; clc;

% Which data to use
useData = 'ica_final'; % 'ica_final' | 'sound_final'

% Stimulation sites
site = {'pfc';'ppc'}; % two different stimulation sites
con = {'C1';'C2'};
conName = {'DXM';'PBO'};

pathDef = 'I:\nmda_tms_eeg\';

% Create input path
if strcmp(useData,'ica_final')
    pathIn = [pathDef,'CLEAN_ICA\'];
elseif strcmp(useData,'sound_final')
    pathIn = [pathDef,'CLEAN_SOUND\'];
end

% Load data 
addpath ('C:\Users\Nigel\Desktop\fieldtrip-20170815');
ft_defaults;

load([pathIn,'grandAverage_N14.mat']);

% Time variable
time = grandAverage.C1.pfc.T0.time*1000;

fig = figure;
set(gcf,'color','w');

N = 0;
figN = {'A','B','C','D'};
for sitex = 1:length(site)
    for conx = 1:length(con)
        if strcmp(site{sitex},'pfc')
            elec = 17; % Fz
        elseif strcmp(site{sitex},'ppc')
            elec = 19; % Pz
        end
        
        data1 = squeeze(grandAverage.(con{conx}).(site{sitex}).T0.individual(:,elec,:));
        data1Mean = mean(data1,1);
        data1CI = (std(data1,[],1)./sqrt(size(data1,1)))*1.96;
        
        data2 = squeeze(grandAverage.(con{conx}).(site{sitex}).T1.individual(:,elec,:));
        data2Mean = mean(data2,1);
        data2CI = (std(data2,[],1)./sqrt(size(data1,1)))*1.96;
        
        N = N+1;
        subplot(2,2,N)
        h1 = plot(time,data1Mean,'b','linewidth',2); hold on;
        f = fill([time,fliplr(time)],[data1Mean-data1CI,fliplr(data1Mean+data1CI)],'b');
        set(f,'FaceAlpha',0.3);set(f,'EdgeColor', 'none');
        
        h2 = plot(time,data2Mean,'r','linewidth',2);
        f = fill([time,fliplr(time)],[data2Mean-data2CI,fliplr(data2Mean+data2CI)],'r');
        set(f,'FaceAlpha',0.3);set(f,'EdgeColor', 'none');
        
        plot([0,0],[-10,10],'k--','linewidth',1.5);
        
        set(gca,'box','off','tickdir','out','xlim',[-100,300],'linewidth',1.5,'fontsize',12);
        
        xlabel('Time (ms)')
        ylabel('Amplitude (\muV)');
        if strcmp(site{sitex},'pfc')
            title(['PFC ',conName{conx},' (Fz)']);
            set(gca,'ylim',[-4,4]);
            text(-170,4*1.1,figN{N},'fontsize',16,'fontweight','bold');
        else
            title(['PAR ',conName{conx},' (Pz)']);
            set(gca,'ylim',[-2,2]);
            text(-170,2*1.1,figN{N},'fontsize',16,'fontweight','bold');
        end
        
        if N==4
            legend([h1,h2],{'Pre','Post'},'box','off','location','southeast','fontsize',12);
        end
        
    end
end

set(fig,'position', [200 200 800 800]);

pathOut = '\figures\';
savename = [pathOut,'TEP_drug_comparison_electrode_',useData];
set(gcf,'PaperPositionMode','auto');
print(fig,'-dsvg',savename);
print(fig,'-dpng',savename);