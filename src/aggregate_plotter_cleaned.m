% neglog = @(foo) ((foo > 0).*log10(foo))+(-(foo<0).*log10(-foo));
% function goo = neglog(foo)
%      goo = ((foo > 0).*log10(foo))+(-(foo<0).*log10(-foo));
%      goo(foo==0) = 0;
% end
% neglog is defined at end of script


% Plotting emerge OHDSI code/concept set patient gain/loss
function aggregate_plotter_cleaned(data_dir, output_dir)

mkdir(output_dir)

% data_dir = '/Users/matthewlevine/code_projects/terminology_information_loss/output_data1';
% output_dir = '/Users/matthewlevine/code_projects/terminology_information_loss/output_plots_local';

% Read in the data
counts_per_set = readtable(sprintf('%s/count_patient_inclusion_per_concept_set.csv',data_dir));
counts_per_code = readtable(sprintf('%s/count_patient_inclusion_per_src_code.csv',data_dir));
% big_table = readtable(sprintf('%s/emerge_final_icd_table.csv',data_dir));
foo_set = readtable(sprintf('%s/concept_set_num_mappings.csv',data_dir));
foo_code = readtable(sprintf('%s/concept_code_num_mappings.csv',data_dir));

% rename some columns
goo = counts_per_set.Properties.VariableNames;
goo{strcmp(goo,'num_patients_per_concept_set_both')} = 'num_patients_both';
goo{strcmp(goo,'num_patients_per_concept_set_src_only')} = 'num_patients_src_only';
goo{strcmp(goo,'num_patients_per_concept_set_map_only')} = 'num_patients_map_only';
counts_per_set.Properties.VariableNames = goo;

goo = counts_per_code.Properties.VariableNames;
goo{strcmp(goo,'num_patients_per_src_code_both')} = 'num_patients_both';
goo{strcmp(goo,'num_patients_per_src_code_src_only')} = 'num_patients_src_only';
goo{strcmp(goo,'num_patients_per_src_code_map_only')} = 'num_patients_map_only';
counts_per_code.Properties.VariableNames = goo;

counts_per_set.fraction_patients_gained = counts_per_set.num_patients_map_only./(counts_per_set.num_patients_both+counts_per_set.num_patients_src_only);
counts_per_set.fraction_patients_lost = counts_per_set.num_patients_src_only./(counts_per_set.num_patients_both+counts_per_set.num_patients_src_only);
counts_per_set.net_fraction_patients_gained = (counts_per_set.num_patients_map_only - counts_per_set.num_patients_src_only)./(counts_per_set.num_patients_both+counts_per_set.num_patients_src_only);
counts_per_set.net_fraction_patients_gained(isnan(counts_per_set.net_fraction_patients_gained)) = 0;
counts_per_set.net_fraction_patients_gained(abs(counts_per_set.net_fraction_patients_gained)==Inf) = NaN;
counts_per_set.sum = counts_per_set.fraction_patients_gained + counts_per_set.fraction_patients_lost;
counts_per_set = sortrows(counts_per_set,'sum','ascend');
counts_per_set.net_patients_gained = counts_per_set.num_patients_map_only-counts_per_set.num_patients_src_only;

counts_per_code.fraction_patients_gained = counts_per_code.num_patients_map_only./(counts_per_code.num_patients_both+counts_per_code.num_patients_src_only);
counts_per_code.fraction_patients_lost = counts_per_code.num_patients_src_only./(counts_per_code.num_patients_both+counts_per_code.num_patients_src_only);
counts_per_code.net_fraction_patients_gained = (counts_per_code.num_patients_map_only - counts_per_code.num_patients_src_only)./(counts_per_code.num_patients_both+counts_per_code.num_patients_src_only);
counts_per_code.net_fraction_patients_gained(isnan(counts_per_code.net_fraction_patients_gained)) = 0;
sprintf('There are %d ICD9 source codes that match 0 patients, but their mappings match patients. These codes will be omitted from histogram plots',sum(counts_per_code.net_fraction_patients_gained==Inf))
counts_per_code.net_fraction_patients_gained(counts_per_code.net_fraction_patients_gained==Inf) = NaN;
counts_per_code.sum = counts_per_code.fraction_patients_gained + counts_per_code.fraction_patients_lost;
counts_per_code = sortrows(counts_per_code,'sum','ascend');
counts_per_code.net_patients_gained = counts_per_code.num_patients_map_only-counts_per_code.num_patients_src_only;

%% add show names
counts_per_set.show_name = repmat({''},height(counts_per_set),1);
for i=1:height(counts_per_set)
    counts_per_set.show_name(i) = strrep(counts_per_set.src_file_name(i),'_eMERGE_Local.sql',strcat('-',counts_per_set.concept_set_name(i)));
end

% counts_per_code.show_name = repmat({''},height(counts_per_code),1);
% for i=1:height(counts_per_code)
%     counts_per_code.show_name(i) = strrep(counts_per_code.src_file_name(i),'_eMERGE_Local.sql',strcat('-',counts_per_code.concept_set_name(i)));
% end

%%
netfig = figure;
ax1 = subplot(2,2,1);hold on;
ax2 = subplot(2,2,2);hold on;
ax3 = subplot(2,2,3);hold on;
ax4 = subplot(2,2,4);hold on;

netfig_rel = figure;
ax1_rel = subplot(2,2,1);hold on;
ax2_rel = subplot(2,2,2);hold on;
ax3_rel = subplot(2,2,3);hold on;
ax4_rel = subplot(2,2,4);hold on;


%% CONCEPT SET section
AA = counts_per_set;
foo = foo_set;


% AA.fraction_patients_gained(AA.fraction_patients_gained==-Inf) = min(AA.fraction_patients_gained(AA.fraction_patients_gained~=-Inf));
% AA.fraction_patients_gained(AA.fraction_patients_gained==Inf) = max(AA.fraction_patients_gained(AA.fraction_patients_gained~=Inf));
AA.sum = AA.num_patients_map_only + AA.num_patients_src_only;
AA = sortrows(AA,'sum','ascend');

% AA.fraction_patients_gained(AA.num_patients_both==0 & AA.num_patients_src_only==0 & AA.num_patients_map_only==0) = 0;
% AA.fraction_patients_lost(AA.num_patients_both==0 & AA.num_patients_src_only==0) = 0;
% AA.fraction_patients_gained(AA.num_patients_both==0 & AA.num_patients_src_only==0 & AA.num_patients_map_only~=0) = max(AA.fraction_patients_gained(AA.fraction_patients_gained~=Inf));

% AA.net_fraction_patients_gained(AA.num_patients_both==0 & AA.num_patients_src_only==0 & AA.num_patients_map_only==0) = 0;

% %% Horizontal bar chart of +%pats and -%pats
% % still need to properly label Y-Axis with names!
% figure;
% hold on;
%
% my_rows = find(~isnan(AA.fraction_patients_gained) & ~isnan(AA.fraction_patients_lost));
% barh(100*AA.fraction_patients_gained(my_rows),'b');
% barh(-100*AA.fraction_patients_lost(my_rows),'r');
% yticks(1:length(my_rows));
% yticklabels(AA.show_name(my_rows))% ,'FontSize',10)
% set(gca,'FontSize',8)
% legend('Patients gained from mapping','Patients lost from mapping')
% xlabel('% change in number of patients')
% ylabel('eMERGE Concept Sets')
% title('Patient gain/loss per eMERGE concept set mapping')
% ylim([length(my_rows)/2 Inf])
% xlim([-Inf Inf])

%% Horizontal bar chart of %+pats and %-pats (USE)
my_rows = find(~isnan(AA.fraction_patients_gained) & ~isnan(AA.fraction_patients_lost));

figure;
hold on;
barh(neglog(100*AA.fraction_patients_gained(my_rows)),'b');
barh(-neglog(100*AA.fraction_patients_lost(my_rows)),'r');
yticks(1:length(my_rows));
yticklabels(AA.show_name(my_rows))% ,'FontSize',10)
set(gca,'FontSize',8)
legend('%-Patients gained from mapping','%-Patients lost from mapping')
xlabel('%-change in number of patients')
title('%-Patient gain/loss per eMERGE concept set mapping')
ylim([1 length(my_rows)/3])
xlim('auto')
my_exponents = get(gca,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents<0) = -10.^abs(my_labels(my_exponents<0));
my_labels(my_exponents>0) = 10.^(my_labels(my_exponents>0));
xticklabels(my_labels)
savefig(sprintf('%s/BarChart1_percent.fig',output_dir))
print(sprintf('%s/BarChart1_percent.png',output_dir),'-dpng','-r300')

figure;
hold on;
barh(neglog(100*AA.fraction_patients_gained(my_rows)),'b');
barh(-neglog(100*AA.fraction_patients_lost(my_rows)),'r');
yticks(1:length(my_rows));
yticklabels(AA.show_name(my_rows))% ,'FontSize',10)
set(gca,'FontSize',8)
legend('%-Patients gained from mapping','%-Patients lost from mapping')
xlabel('%-change in number of patients')
title('%-Patient gain/loss per eMERGE concept set mapping')
ylim([length(my_rows)*0.33 length(my_rows)*0.66])
xlim('auto')
my_exponents = get(gca,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents<0) = -10.^abs(my_labels(my_exponents<0));
my_labels(my_exponents>0) = 10.^(my_labels(my_exponents>0));
xticklabels(my_labels)
savefig(sprintf('%s/BarChart2_percent.fig',output_dir))
print(sprintf('%s/BarChart2_percent.png',output_dir),'-dpng','-r300')

figure;
hold on;
barh(neglog(100*AA.fraction_patients_gained(my_rows)),'b');
barh(-neglog(100*AA.fraction_patients_lost(my_rows)),'r');
yticks(1:length(my_rows));
yticklabels(AA.show_name(my_rows))% ,'FontSize',10)
set(gca,'FontSize',8)
legend('%-Patients gained from mapping','%-Patients lost from mapping')
xlabel('%-change in number of patients')
title('%-Patient gain/loss per eMERGE concept set mapping')
ylim([length(my_rows)*0.66 Inf])
xlim('auto')
my_exponents = get(gca,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents<0) = -10.^abs(my_labels(my_exponents<0));
my_labels(my_exponents>0) = 10.^(my_labels(my_exponents>0));
xticklabels(my_labels)
savefig(sprintf('%s/BarChart3_percent.fig',output_dir))
print(sprintf('%s/BarChart3_percent.png',output_dir),'-dpng','-r300')

%% Horizontal bar chart of +pats and -pats (USE)
% still need to properly label Y-Axis with names!
my_rows = find(~isnan(AA.fraction_patients_gained) & ~isnan(AA.fraction_patients_lost));

show_rows = sort(datasample(my_rows,33,'Replace',false));
figure;
hold on;
barh(log10(AA.num_patients_map_only(show_rows)),'b');
barh(-log10(AA.num_patients_src_only(show_rows)),'r');
yticks(1:length(show_rows));
yticklabels(AA.show_name(show_rows))% ,'FontSize',10)
set(gca,'FontSize',8)
legend('Patients gained from mapping','Patients lost from mapping')
xlabel('Number of patients')
title('Patient gain/loss per eMERGE concept set mapping')
% ylim([1 length(my_rows)/3])
% xlim('auto')
my_exponents = get(gca,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents<0) = -10.^abs(my_labels(my_exponents<0));
my_labels(my_exponents>0) = 10.^(my_labels(my_exponents>0));
xticklabels(my_labels)
savefig(sprintf('%s/BarChartRand.fig',output_dir))
print(sprintf('%s/BarChartRand.png',output_dir),'-dpng','-r300')


figure;
hold on;
barh(log10(AA.num_patients_map_only(my_rows)),'b');
barh(-log10(AA.num_patients_src_only(my_rows)),'r');
yticks(1:length(my_rows));
yticklabels(AA.show_name(my_rows))% ,'FontSize',10)
set(gca,'FontSize',8)
legend('Patients gained from mapping','Patients lost from mapping')
xlabel('Number of patients')
title('Patient gain/loss per eMERGE concept set mapping')
ylim([1 length(my_rows)/3])
xlim('auto')
my_exponents = get(gca,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents<0) = -10.^abs(my_labels(my_exponents<0));
my_labels(my_exponents>0) = 10.^(my_labels(my_exponents>0));
xticklabels(my_labels)
savefig(sprintf('%s/BarChart1.fig',output_dir))
print(sprintf('%s/BarChart1.png',output_dir),'-dpng','-r300')

figure;
hold on;
barh(log10(AA.num_patients_map_only(my_rows)),'b');
barh(-log10(AA.num_patients_src_only(my_rows)),'r');
yticks(1:length(my_rows));
yticklabels(AA.show_name(my_rows))% ,'FontSize',10)
set(gca,'FontSize',8)
legend('Patients gained from mapping','Patients lost from mapping')
xlabel('Number of patients')
title('Patient gain/loss per eMERGE concept set mapping')
ylim([length(my_rows)*0.33 length(my_rows)*0.66])
xlim([-Inf Inf])
my_exponents = get(gca,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents<0) = -10.^abs(my_labels(my_exponents<0));
my_labels(my_exponents>0) = 10.^(my_labels(my_exponents>0));
xticklabels(my_labels)
savefig(sprintf('%s/BarChart2.fig',output_dir))
print(sprintf('%s/BarChart2.png',output_dir),'-dpng','-r300')

figure;
hold on;
barh(log10(AA.num_patients_map_only(my_rows)),'b');
barh(-log10(AA.num_patients_src_only(my_rows)),'r');
yticks(1:length(my_rows));
yticklabels(AA.show_name(my_rows))% ,'FontSize',10)
set(gca,'FontSize',8)
legend('Patients gained from mapping','Patients lost from mapping')
xlabel('Number of patients')
title('Patient gain/loss per eMERGE concept set mapping')
ylim([length(my_rows)*0.66 Inf])
xlim([-Inf Inf])
my_exponents = get(gca,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents<0) = -10.^abs(my_labels(my_exponents<0));
my_labels(my_exponents>0) = 10.^(my_labels(my_exponents>0));
xticklabels(my_labels)
savefig(sprintf('%s/BarChart3.fig',output_dir))
print(sprintf('%s/BarChart3.png',output_dir),'-dpng','-r300')

%% HISTOGRAMS of +pats and -pats (USE)
figure;

subplot(2,2,1)

X = log10(AA.num_patients_map_only);
X(X==-Inf) = 0;
X(isnan(X)) = min(X);
histogram(X,12)
% histogram(100*AA.fraction_patients_lost(my_rows))
xlabel('Number of patients')
ylabel('Number of eMERGE concept sets')
title('Patients GAINED')
my_exponents = get(gca,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents~=0) = 10.^my_exponents(my_exponents~=0);
xticklabels(my_labels)

% xlim([-1 4])

subplot(2,2,2)

X = log10(AA.num_patients_src_only);
X(X==-Inf) = 0;
X(X==Inf) = max(X(X~=Inf));
histogram(X,12)
% histogram(100*AA.fraction_patients_lost(my_rows))
xlabel('Number of patients')
ylabel('Number of eMERGE concept sets')
title('Patients LOST')
% xlim([-3 3])
my_exponents = get(gca,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents~=0) = 10.^my_exponents(my_exponents~=0);
xticklabels(my_labels)


suptitle('Patient loss and gain per eMERGE concept set mapping')

% %% KSdensity of +%-pats and -%-pats (USE)
% figure;

% thresh = Inf;
% goo = AA(abs(AA.fraction_patients_gained)<thresh,:);

% gains
subplot(2,2,3)
hold on;
my_bw = 0.3;
my_rows = ismember(AA.idx,foo.idx(foo.has0==0 & foo.has2==0 & foo.has3==0));
X = log10(AA.num_patients_map_only(my_rows));
X(X==-Inf) = 0;
X(isnan(X)) = min(X);
ksdensity(X,'Bandwidth',my_bw)
num_all = sum(my_rows);

my_rows = ismember(AA.idx,foo.idx(foo.has0==1));
X = log10(AA.num_patients_map_only(my_rows));
X(X==-Inf) = 0;
X(isnan(X)) = min(X);
ksdensity(X,'Bandwidth',my_bw)
num_null = sum(my_rows);

my_rows = ismember(AA.idx,foo.idx(foo.has2==1 | foo.has3==1));
X = log10(AA.num_patients_map_only(my_rows));
X(X==-Inf) = 0;
X(isnan(X)) = min(X);
ksdensity(X,'Bandwidth',my_bw)
num_multi = sum(my_rows);

legend(sprintf('has only 1-1 mappings (%d)',num_all),sprintf('has INVALID mapping (%d)',num_null),sprintf('has a MULTI mapping (%d)',num_multi))
xlabel('Number of patients')
ylabel('Fraction of eMERGE concept sets')
title('(by code type)')
% xlim([-1 4])
my_exponents = get(gca,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents~=0) = 10.^my_exponents(my_exponents~=0);
xticklabels(my_labels)

% losses
subplot(2,2,4)
hold on;
my_bw = 0.3;

my_rows = ismember(AA.idx,foo.idx(foo.has0==0 & foo.has2==0 & foo.has3==0));
X = log10(AA.num_patients_src_only(my_rows));
X(X==-Inf) = 0;
X(X==Inf) = max(X(X~=Inf));
ksdensity(X,'Bandwidth',my_bw)
num_all = sum(my_rows);

my_rows = ismember(AA.idx,foo.idx(foo.has0==1));
X = log10(AA.num_patients_src_only(my_rows));
X(X==-Inf) = 0;
X(X==Inf) = max(X(X~=Inf));
ksdensity(X,'Bandwidth',my_bw)
num_null = sum(my_rows);

my_rows = ismember(AA.idx,foo.idx(foo.has2==1 | foo.has3==1));
X = log10(AA.num_patients_src_only(my_rows));
X(X==-Inf) = 0;
X(X==Inf) = max(X(X~=Inf));
ksdensity(X,'Bandwidth',my_bw)
num_multi = sum(my_rows);

legend(sprintf('has only 1-1 mappings (%d)',num_all),sprintf('has INVALID mapping (%d)',num_null),sprintf('has a MULTI mapping (%d)',num_multi))
xlabel('Number of patients')
title('(by code type)')
ylabel('Fraction of eMERGE concept sets')
% xlim([-3 3])
my_exponents = get(gca,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents~=0) = 10.^my_exponents(my_exponents~=0);
xticklabels(my_labels)

savefig(sprintf('%s/ConceptSet_GainLoss.fig',output_dir))
print(sprintf('%s/ConceptSet_GainLoss.png',output_dir),'-dpng','-r300')


%% Histogram of NET patient change per concept set (USE)
X = neglog(AA.net_patients_gained);
% Y = real(X);
% X(imag(X)~=0) = min(Y(Y~=-Inf)); %log10 of, say -60 turns complex in matlab cuz numerics
% X(X==-Inf) = min(X(X~=-Inf));
% X(X==Inf) = max(X(X~=Inf));
histogram(ax1,X,15)
% histogram(100*counts_per_set.net_fraction_patients_gained,15)
ylabel(ax1,'Number of concept sets')
xlabel(ax1,'Net change in total patient count')
title(ax1,'Net change in patients per concept-set mapping')
% xlim(ax1,[0 6])

X = neglog(100*AA.net_fraction_patients_gained);
% Y = real(X);
% X(imag(X)~=0) = min(Y(Y~=-Inf)); %log10 of, say -60 turns complex in matlab cuz numerics
% X(X==-Inf) = min(X(X~=-Inf));
% X(X==Inf) = max(X(X~=Inf));
histogram(ax1_rel,X,15)
% histogram(100*counts_per_set.net_fraction_patients_gained,15)
ylabel(ax1_rel,'Number of concept sets')
xlabel(ax1_rel,'Net %-change in total patient count')
title(ax1_rel,'Net change in patients per concept-set mapping')


%% absolute KDEs
my_bw = [];

my_rows = ismember(AA.idx,foo.idx(foo.has0==0 & foo.has2==0 & foo.has3==0));
X = neglog(AA.net_patients_gained(my_rows));
% Y = real(X);
% X(imag(X)~=0) = min(Y(Y~=-Inf)); %log10 of, say -60 turns complex in matlab cuz numerics
% X(X==-Inf) = min(X(X~=-Inf));
% X(X==Inf) = max(X(X~=Inf));
ksdensity(ax3,X,'Bandwidth',my_bw)
num_all = sum(my_rows);

my_rows = ismember(AA.idx,foo.idx(foo.has0==1));
X = neglog(AA.net_patients_gained(my_rows));
% Y = real(X);
% X(imag(X)~=0) = min(Y(Y~=-Inf)); %log10 of, say -60 turns complex in matlab cuz numerics
% X(X==-Inf) = min(X(X~=-Inf));
% X(X==Inf) = max(X(X~=Inf));
ksdensity(ax3,X,'Bandwidth',my_bw)
num_null = sum(my_rows);

my_rows = ismember(AA.idx,foo.idx(foo.has2==1 | foo.has3==1));
X = neglog(AA.net_patients_gained(my_rows));
% Y = real(X);
% X(imag(X)~=0) = min(Y(Y~=-Inf)); %log10 of, say -60 turns complex in matlab cuz numerics
% X(X==-Inf) = min(X(X~=-Inf));
% X(X==Inf) = max(X(X~=Inf));
ksdensity(ax3,X,'Bandwidth',my_bw)
num_multi = sum(my_rows);

legend(ax3,sprintf('has only 1-1 mappings (%d)',num_all),sprintf('has INVALID mapping (%d)',num_null),sprintf('has a MULTI mapping (%d)',num_multi))
xlabel(ax3,'Net change in total patient count')
title(ax3,'(by code type)')
ylabel(ax3,'Frequency of eMERGE concept sets')
% xlim(ax3,[0 6])

%% relative KDEs
my_bw = [];

my_rows = ismember(AA.idx,foo.idx(foo.has0==0 & foo.has2==0 & foo.has3==0));
X = neglog(100*AA.net_fraction_patients_gained(my_rows));
% Y = real(X);
% X(imag(X)~=0) = min(Y(Y~=-Inf)); %log10 of, say -60 turns complex in matlab cuz numerics
% X(X==-Inf) = min(X(X~=-Inf));
% X(X==Inf) = max(X(X~=Inf));
ksdensity(ax3_rel,X,'Bandwidth',my_bw)
num_all = sum(my_rows);

my_rows = ismember(AA.idx,foo.idx(foo.has0==1));
X = neglog(100*AA.net_fraction_patients_gained(my_rows));
% Y = real(X);
% X(imag(X)~=0) = min(Y(Y~=-Inf)); %log10 of, say -60 turns complex in matlab cuz numerics
% X(X==-Inf) = min(X(X~=-Inf));
% X(X==Inf) = max(X(X~=Inf));
ksdensity(ax3_rel,X,'Bandwidth',my_bw)
num_null = sum(my_rows);

my_rows = ismember(AA.idx,foo.idx(foo.has2==1 | foo.has3==1));
X = neglog(100*AA.net_fraction_patients_gained(my_rows));
% Y = real(X);
% X(imag(X)~=0) = min(Y(Y~=-Inf)); %log10 of, say -60 turns complex in matlab cuz numerics
% X(X==-Inf) = min(X(X~=-Inf));
% X(X==Inf) = max(X(X~=Inf));
ksdensity(ax3_rel,X,'Bandwidth',my_bw)
num_multi = sum(my_rows);

legend(ax3_rel,sprintf('has only 1-1 mappings (%d)',num_all),sprintf('has INVALID mapping (%d)',num_null),sprintf('has a MULTI mapping (%d)',num_multi))
xlabel(ax3_rel,'Net %-change in total patient count')
title(ax3_rel,'(by code type)')
ylabel(ax3_rel,'Number of eMERGE concept sets')
% xlim(ax3,[0 6])

%% CONCEPT CODE section
BB = counts_per_code;
foo_code.Properties.VariableNames{1} = 'idx';

% counts_per_code.fraction_patients_gained = counts_per_code.num_patients_map_only./counts_per_code.num_patients_both;
% counts_per_code.fraction_patients_lost = counts_per_code.num_patients_src_only./counts_per_code.num_patients_both;

% AA.net_fraction_patients_gained = (AA.num_patients_map_only - AA.num_patients_src_only)./(AA.num_patients_both+AA.num_patients_src_only);

% BB.fraction_patients_gained(BB.fraction_patients_gained==-Inf) = min(BB.fraction_patients_gained(BB.fraction_patients_gained~=-Inf));
BB.fraction_patients_gained(BB.fraction_patients_gained==Inf) = max(BB.fraction_patients_gained(BB.fraction_patients_gained~=Inf));
BB.sum = BB.fraction_patients_gained + BB.fraction_patients_lost;
BB = sortrows(BB,'sum','ascend');

%%
% BB.fraction_patients_gained(BB.num_patients_both==0 & BB.num_patients_src_only==0 & BB.num_patients_map_only==0) = 0;
% BB.fraction_patients_lost(BB.num_patients_both==0 & BB.num_patients_src_only==0) = 0;
% BB.fraction_patients_gained(BB.num_patients_both==0 & BB.num_patients_src_only==0 & BB.num_patients_map_only~=0) = max(BB.fraction_patients_gained(BB.fraction_patients_gained~=Inf));

% BB.net_fraction_patients_gained(BB.num_patients_both==0 & BB.num_patients_src_only==0 & BB.num_patients_map_only==0) = 0;

% BB.net_patients_gained = BB.num_patients_map_only-BB.num_patients_src_only;

% BB.fraction_patients_gained(BB.fraction_patients_gained==0) = 0.00001;
% BB.fraction_patients_lost(BB.fraction_patients_lost==0) = 0.00001;

% %% HISTOGRAMS of %+pats and %-pats (USE)
% figure;
%
% subplot(2,2,1)
% X = log10(BB.num_patients_map_only);
% X(X==-Inf) = 0;
% X(X==Inf) = max(X(X~=Inf));
% histogram(X,12)
% % histogram(100*AA.fraction_patients_lost(my_rows))
% xlabel('Number of patients')
% ylabel('Number of ICD9CM codes')
% title('Patients GAINED')
% % xlim([-3 8])
% my_exponents = get(gca,'XTick');
% my_labels = my_exponents;
% my_labels(my_exponents==0) = 0;
% my_labels(my_exponents~=0) = 10.^my_exponents(my_exponents~=0);
% xticklabels(my_labels)
%
% subplot(2,2,2)
%
% X = log10(BB.num_patients_src_only);
% X(X==-Inf) = 0;
% X(X==Inf) = max(X(X~=Inf));
% histogram(X,12)
% % histogram(100*AA.fraction_patients_lost(my_rows))
% xlabel('Number of patients')
% ylabel('Number of ICD9CM codes')
% title('Patients LOST')
% % xlim([-3 8])
% my_exponents = get(gca,'XTick');
% my_labels = my_exponents;
% my_labels(my_exponents==0) = 0;
% my_labels(my_exponents~=0) = 10.^my_exponents(my_exponents~=0);
% xticklabels(my_labels)
%
% % gains
% subplot(2,2,3)
% my_bw = 0.3;
% hold on;
%
% my_rows = ismember(BB.concept_id,foo_code.idx(foo_code.has0==0 & foo_code.has2==0 & foo_code.has3==0));
% X = log10(BB.num_patients_map_only(my_rows));
% X(X==-Inf) = 0;
% X(X==Inf) = max(X(X~=Inf));
% ksdensity(X,'Bandwidth',my_bw)
% num_all = sum(my_rows);
%
% my_rows = ismember(BB.concept_id,foo_code.idx(foo_code.has0==1));
% X = log10(BB.num_patients_map_only(my_rows));
% X(X==-Inf) = 0;
% X(X==Inf) = max(X(X~=Inf));
% ksdensity(X,'Bandwidth',my_bw)
% num_null = sum(my_rows);
%
% my_rows = ismember(BB.concept_id,foo_code.idx(foo_code.has2==1 | foo_code.has3==1));
% X = log10(BB.num_patients_map_only(my_rows));
% X(X==-Inf) = 0;
% X(X==Inf) = max(X(X~=Inf));
% ksdensity(X,'Bandwidth',my_bw)
% num_multi = sum(my_rows);
%
% legend(sprintf('has 1-1 mapping (%d)',num_all),sprintf('has only INVALID mapping (%d)',num_null),sprintf('has a MULTI mapping (%d)',num_multi))
% xlabel('Number of patients')
% ylabel('Frequency of ICD9CM codes')
% title('(by code type)')
% % xlim([-3 8])
% my_exponents = get(gca,'XTick');
% my_labels = my_exponents;
% my_labels(my_exponents==0) = 0;
% my_labels(my_exponents~=0) = 10.^my_exponents(my_exponents~=0);
% xticklabels(my_labels)
%
%
% % losses
% subplot(2,2,4)
% my_bw = 0.3;
% hold on;
%
% my_rows = ismember(BB.concept_id,foo_code.idx(foo_code.has0==0 & foo_code.has2==0 & foo_code.has3==0));
% num_all = sum(my_rows);
% X = log10(BB.num_patients_src_only(my_rows));
% % X(X==-Inf) = min(X(X~=-Inf));
% X(X==-Inf) = 0;
% X(X==Inf) = max(X(X~=Inf));
% ksdensity(X,'Bandwidth',my_bw)
%
% my_rows = ismember(BB.concept_id,foo_code.idx(foo_code.has0==1));
% X = log10(BB.num_patients_src_only(my_rows));
% X(X==-Inf) = 0;
% X(X==Inf) = max(X(X~=Inf));
% ksdensity(X,'Bandwidth',my_bw)
% num_null = sum(my_rows);
%
% my_rows = ismember(BB.concept_id,foo_code.idx(foo_code.has2==1 | foo_code.has3==1));
% X = log10(BB.num_patients_src_only(my_rows));
% % X(X==-Inf) = min(X(X~=-Inf));
% X(X==-Inf) = 0;
% X(X==Inf) = max(X(X~=Inf));
% ksdensity(X,'Bandwidth',my_bw)
% num_multi = sum(my_rows);
%
% legend(sprintf('has a 1-1 mapping (%d)',num_all),sprintf('has only INVALID mapping (%d)',num_null),sprintf('has a MULTI mapping (%d)',num_multi))
% xlabel('Number of patients')
% ylabel('Frequency of ICD9CM codes')
% title('(by code type)')
% % xlim([-3 8])
%
% my_exponents = get(gca,'XTick');
% my_labels = my_exponents;
% my_labels(my_exponents==0) = 0;
% my_labels(my_exponents~=0) = 10.^my_exponents(my_exponents~=0);
% xticklabels(my_labels)
%
% suptitle('Patient loss and gain per ICD9 mapping')
%
% savefig(sprintf('%s/ConceptCodes_GainLoss.fig',output_dir))
% print(sprintf('%s/ConceptCodes_GainLoss.png',output_dir),'-dpng','-r300')

%% Histogram of NET patient change per concept set (USE)

X = neglog(BB.net_patients_gained);
histogram(ax2,X,15)

ylabel(ax2,'Number of concepts')
xlabel(ax2,'Net change in total patient count')
title(ax2,'Net change in patients per concept mapping')
% xlim(ax2,[0 6])

X = neglog(100*BB.net_fraction_patients_gained);
histogram(ax2_rel,X,15)
ylabel(ax2_rel,'Number of concepts')
xlabel(ax2_rel,'Net %-change in total patient count')
title(ax2_rel,'Net %-change in patients per concept mapping')


%% absolute KDEs
my_bw = [];
my_rows = ismember(BB.concept_id,foo_code.idx(foo_code.has0==0 & foo_code.has2==0 & foo_code.has3==0));
X = neglog(BB.net_patients_gained(my_rows));
% Y = real(X);
% X(imag(X)~=0) = min(Y(Y~=-Inf)); %log10 of, say -60 turns complex in matlab cuz numerics
% X(X==-Inf) = min(X(X~=-Inf));
% X(X==Inf) = max(X(X~=Inf));
ksdensity(ax4,X,'Bandwidth',my_bw)
num_all = sum(my_rows);

my_rows = ismember(BB.concept_id,foo_code.idx(foo_code.has0==1));
X = neglog(BB.net_patients_gained(my_rows));
% Y = real(X);
% X(imag(X)~=0) = min(Y(Y~=-Inf)); %log10 of, say -60 turns complex in matlab cuz numerics
% X(X==-Inf) = min(X(X~=-Inf));
% X(X==Inf) = max(X(X~=Inf));
ksdensity(ax4,X,'Bandwidth',my_bw)
num_null = sum(my_rows);

my_rows = ismember(BB.concept_id,foo_code.idx(foo_code.has2==1 | foo_code.has3==1));
X = neglog(BB.net_patients_gained(my_rows));
% Y = real(X);
% X(imag(X)~=0) = min(Y(Y~=-Inf)); %log10 of, say -60 turns complex in matlab cuz numerics
% X(X==-Inf) = min(X(X~=-Inf));
% X(X==Inf) = max(X(X~=Inf));
ksdensity(ax4,X,'Bandwidth',my_bw)
num_multi = sum(my_rows);

legend(ax4,sprintf('has only 1-1 mappings (%d)',num_all),sprintf('has INVALID mapping (%d)',num_null),sprintf('has a MULTI mapping (%d)',num_multi))
xlabel(ax4,'Net change in total patient count')
ylabel(ax4,'Frequency of ICD9CM codes')
title(ax4,'(by code type)')
% xlim(ax4,[0 6])

%% relative KDEs
my_bw = [];
my_rows = ismember(BB.concept_id,foo_code.idx(foo_code.has0==0 & foo_code.has2==0 & foo_code.has3==0));
X = neglog(100*BB.net_fraction_patients_gained(my_rows));
% Y = real(X);
% X(imag(X)~=0) = min(Y(Y~=-Inf)); %log10 of, say -60 turns complex in matlab cuz numerics
% X(X==-Inf) = min(X(X~=-Inf));
% X(X==Inf) = max(X(X~=Inf));
ksdensity(ax4_rel,X,'Bandwidth',my_bw)
num_all = sum(my_rows);

my_rows = ismember(BB.concept_id,foo_code.idx(foo_code.has0==1));
X = neglog(100*BB.net_fraction_patients_gained(my_rows));
% Y = real(X);
% X(imag(X)~=0) = min(Y(Y~=-Inf)); %log10 of, say -60 turns complex in matlab cuz numerics
% X(X==-Inf) = min(X(X~=-Inf));
% X(X==Inf) = max(X(X~=Inf));
ksdensity(ax4_rel,X,'Bandwidth',my_bw)
num_null = sum(my_rows);

my_rows = ismember(BB.concept_id,foo_code.idx(foo_code.has2==1 | foo_code.has3==1));
X = neglog(100*BB.net_fraction_patients_gained(my_rows));
% Y = real(X);
% X(imag(X)~=0) = min(Y(Y~=-Inf)); %log10 of, say -60 turns complex in matlab cuz numerics
% X(X==-Inf) = min(X(X~=-Inf));
% X(X==Inf) = max(X(X~=Inf));
ksdensity(ax4_rel,X,'Bandwidth',my_bw)
num_multi = sum(my_rows);

legend(ax4_rel,sprintf('has only 1-1 mappings (%d)',num_all),sprintf('has INVALID mapping (%d)',num_null),sprintf('has a MULTI mapping (%d)',num_multi))
xlabel(ax4_rel,'Net %-change in total patient count')
ylabel(ax4_rel,'Number of ICD9CM codes')
title(ax4_rel,'(by code type)')
% xlim(ax4,[0 6])

%% clean up absolute plot
my_exponents = get(ax1,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents<0) = -10.^abs(my_labels(my_exponents<0));
my_labels(my_exponents>0) = 10.^(my_labels(my_exponents>0));
xticklabels(ax1,my_labels)
title(ax1,'Net patient change per eMERGE concept set mapping')

my_exponents = get(ax2,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents<0) = -10.^abs(my_labels(my_exponents<0));
my_labels(my_exponents>0) = 10.^(my_labels(my_exponents>0));
xticklabels(ax2,my_labels)
title(ax2,'Net patient change per ICD9 mapping')

my_exponents = get(ax3,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents<0) = -10.^abs(my_labels(my_exponents<0));
my_labels(my_exponents>0) = 10.^(my_labels(my_exponents>0));
xticklabels(ax3,my_labels)

my_exponents = get(ax4,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents<0) = -10.^abs(my_labels(my_exponents<0));
my_labels(my_exponents>0) = 10.^(my_labels(my_exponents>0));
xticklabels(ax4,my_labels)

savefig(netfig,sprintf('%s/NetPatientChange.fig',output_dir))
print(netfig,sprintf('%s/NetPatientChange.png',output_dir),'-dpng','-r300')

%% clean up relative plot
my_exponents = get(ax1_rel,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents<0) = -10.^abs(my_labels(my_exponents<0));
my_labels(my_exponents>0) = 10.^(my_labels(my_exponents>0));
xticklabels(ax1_rel,my_labels)
title(ax1_rel,'Net %-patient change per eMERGE concept set mapping')

my_exponents = get(ax2_rel,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents<0) = -10.^abs(my_labels(my_exponents<0));
my_labels(my_exponents>0) = 10.^(my_labels(my_exponents>0));
xticklabels(ax2_rel,my_labels)
title(ax2_rel,'Net %-patient change per ICD9 mapping')

my_exponents = get(ax3_rel,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents<0) = -10.^abs(my_labels(my_exponents<0));
my_labels(my_exponents>0) = 10.^(my_labels(my_exponents>0));
xticklabels(ax3_rel,my_labels)

my_exponents = get(ax4_rel,'XTick');
my_labels = my_exponents;
my_labels(my_exponents==0) = 0;
my_labels(my_exponents<0) = -10.^abs(my_labels(my_exponents<0));
my_labels(my_exponents>0) = 10.^(my_labels(my_exponents>0));
xticklabels(ax4_rel,my_labels)

savefig(netfig_rel,sprintf('%s/NetPercentPatientChange.fig',output_dir))
print(netfig_rel,sprintf('%s/NetPercentPatientChange.png',output_dir),'-dpng','-r300')


%%
function goo = neglog(foo)
%% Please note that this function only makes sense to use when data are not between -1 and 1 (zero is OK though).
% in those cases, you get a negative exponent, and things dont work!!!
b = sum(abs(foo)>0 & abs(foo)<1);
if b>0
    warning('Improper use case of neglog...input contains values between 0 and 1 or 0 and -1.')
    warning('Rounding these cases to 1 or -1')
    foo(foo<1 & foo>0) = 1;
    foo(foo>-1 & foo<0) = -1;
    b
    b/length(foo)
end
goo = ((foo > 0).*log10(foo))+(-(foo<0).*log10(-foo));
goo(foo==0) = 0;
end

end

