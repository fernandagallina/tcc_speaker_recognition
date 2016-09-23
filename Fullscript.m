DirData = dir('Audios\');
dirIndex = [DirData.isdir];
fileList = {DirData(~dirIndex).name};

fid = fopen('dataList.txt', 'wt');

for i=1:numel(fileList)
    [samples, Fs] = audioread(strcat('Audios\',fileList{i}));
    [c,tc]=melcepst(samples,Fs,'0dD');
    writehtk(strcat('htkfiles\',strtok(fileList{i},'.'),'.htk'),c,1/Fs,6);
    fprintf(fid, '%s\n',strcat('htkfiles\',strtok(fileList{i},'.'),'.htk'));
    %[d,fp,dt,code,t]=readhtk('.\htkfiles\test.htk');
end

%% Step1: Training the UBM
dataList = 'dataList.txt';
nmix = 256;
final_niter = 10;
ds_factor = 1;
ubm = gmm_em(dataList, nmix, final_niter, ds_factor, 'ubm');

%% Step2: Adapting the speaker models from UBM
fea_dir = 'htkfiles\';
fea_ext = '.htk';
fid = fopen('dataList.txt', 'rt');
C = textscan(fid, '%s %s');
fclose(fid);
model_ids = unique(C{1}, 'stable');
model_files = C{2};
nspks = length(model_ids);
map_tau = 10.0;
config = 'mwv';
gmm_models = cell(nspks, 1); 
for spk = 1 : nspks,
    ids = find(ismember(C{1}, model_ids{spk}));
    spk_files = model_files(ids);
    spk_files = cellfun(@(x) fullfile(fea_dir, [x, fea_ext]),...  %# Prepend path to files
                       spk_files, 'UniformOutput', false);
    gmm_models{spk} = mapAdapt('dataList.txt', ubm, map_tau, config);
end