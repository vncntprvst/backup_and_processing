%parse_widefield_nwb.m
%v. 1.2
%LAST EDIT: 5-SEP-2024
%AUTHOR: Duane Rinehart (drinehart@ucsd.edu)

%#################################################################
% APP CONSTANTS (DEFAULT)
% Paths may be overridden via environment variables so this script does not
% need to be edited per machine. Defaults below are examples. Override with:
%   WF_ACQUISITION_PATH, WF_FILTERS_PATH, WF_OUTPUT_PATH, WF_TEMPLATE_XLSX
default_root        = "F:/Jacob/";
acquisition_path    = getenv_default("WF_ACQUISITION_PATH", default_root);
filters_input_path  = getenv_default("WF_FILTERS_PATH", default_root); %user-edit file
output_path         = getenv_default("WF_OUTPUT_PATH", default_root + "output/"); %recordings file written to this location
template_input_path = getenv_default("WF_TEMPLATE_XLSX", default_root + "input_widefield.xlsx"); %Excel file to store summary [of all experiments]
%#################################################################

%PRE-PROCESSING / PREREQUISITES
% Check if output_path exists, create it if not [TRAP ERROR EARLY TO AVOID
% GOING THROUGH PROCESS IF OUTPUT LOCATION IS NOW WRITEABLE]
if ~exist(output_path, 'dir')
    mkdir(output_path);
end
warning('off','all')

%ENABLE LOGGING - ref: https://www.mathworks.com/help/matlab/ref/diary.html
diary_file = fullfile(output_path, 'matlab.log');
diary off; % Ensure any previous diary is closed
diary(diary_file);
diary on; % Explicitly turn on diary logging

%LOG ENTRY
timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
disp('******************************')
fprintf('%s - CURRENT RUN PARAMETERS\n', timestamp);
fprintf('%s - acquisition_path: %s\n', timestamp, acquisition_path);
fprintf('%s - output_path: %s\n', timestamp, output_path);

%READ FILTERS FILE
filters_file = fullfile(filters_input_path, 'filters.txt');
raw_filters = fileread(filters_file);
assert(~isempty(raw_filters), 'Error: File is empty or could not be read');
if ~ischar(raw_filters) && ~isstring(raw_filters)
    error('Error: File content is not a valid character vector or string');
end
kv_filters = parse_filters(raw_filters);

%GET LIST OF FOLDERS (ACQUISITION IMAGE SEQUENCES)
items = dir(acquisition_path);
    
% Filter the list to include only directories, excluding '.' and '..'
isDir = [items.isdir];
folderNames = {items(isDir).name};

% Remove '.', '..', 'output' from the list of folders

% % Extract the last part of the path (folder name)
% [~, output_folder_name, ~] = fileparts(output_path);
% disp(['DEBUG:',output_folder_name]);
% % Remove trailing slash if present
% if isempty(output_folder_name)
%     [~, output_folder_name, ~] = fileparts(output_path(1:end-1));
% end
% output_folder_name = char(output_folder_name);
% disp(['DEBUG2:',output_folder_name]);

folderList = folderNames(~ismember(folderNames, {'.', '..', 'output'}));

for i = 1:length(folderList)
    % Construct the full path to the 'metadata.txt' file in the "Default" subfolder
    defaultFolder = fullfile(acquisition_path, folderList{i}, 'Default');
    metadataFile = fullfile(defaultFolder, 'metadata.txt');
    recordings_name = folderList{i};

    % Check if the 'metadata.txt' file exists
    if isfile(metadataFile)
        fprintf('FOUND: %s\n', metadataFile);
        
        %CONSTRUCT THE OUTPUT META-DATA FILENAME
        recordings_name = sanitize_filename(recordings_name);
        fileName = fullfile(output_path, ['recordings_widefield_', recordings_name, '.xlsx']);
        
        %CHECK OUTPUT FOLDER TO SEE IF RECORDINGS FILE PREVIOUSLY GENERATED
        if isfile(fileName)
            disp(['SKIPPING META-DATA GENERATION FOR "', folderList{i}, '";', fileName, 'EXISTS']); 
            continue
        else
            disp(['GENERATING META-DATA FILE FOR "', folderList{i}, '"']); 
        end
        
        %READ METADATA FILE (Default/metadata.txt)
        raw_metadata = fileread(metadataFile);
        assert(~isempty(raw_metadata), 'Error: File is empty or could not be read');
        if ~ischar(raw_metadata) && ~isstring(raw_metadata)
            error('Error: File content is not a valid character vector or string');
        end
        
        %DECODE JSON
        try
            metadata = jsondecode(char(raw_metadata)); % Convert to character vector if needed
            assert(~isempty(metadata), 'Error: JSON decoding resulted in an empty structure');
        catch ME
            error('Error decoding JSON: %s', ME.message);
        end
        
        parse_metadata_create_summary_doc(metadata, kv_filters, fileName, recordings_name);
    else
        fprintf('SKIPPING %s\n', defaultFolder);
    end
end

%LOG ENTRY
timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
disp('******************************')
disp('SUMMARY')
fprintf('OUTPUT FOLDER SHOULD HAVE %d EXCEL FILES (META-DATA), BASED ON FOLDER COUNT\n', numel(folderList));
output_items = dir(fullfile(output_path, '*.xlsx'));
num_xlsx_files = numel(output_items);
fprintf('COUNT OF .xlsx FILES IN OUTPUT FOLDER: %d\n', num_xlsx_files);
fprintf('CURRENT RUN COMPLETED @ %s\n', timestamp);
disp('******************************')

% OUTSTANDING/STEPS (5-SEP-2024)
% 2- create excel template (from meta-data file); unclear if still needed


%create .com/.ps1 for before sync to call parse_widefield.m
%'UserData' does not seem to be captures from metadata.txt file
%sha256sum of each file, and manifest of all files?
%h5 conversion of image sequences [SLURM]
%append to master experiments sheet (for widefield)

function kv_filters = parse_filters(raw_filters)
    %PARSE_FILTERS Parses a file with key-value pairs into a structure
    %   INPUT: 
    %     raw_filters - text file contents containing key-value pairs
    %   OUTPUT:
    %     data - structure containing parsed key-value pairs
    
    lines = strsplit(raw_filters, '\n');
    % Estimate the number of non-empty, non-comment lines
    numLines = sum(~cellfun(@isempty, lines) & cellfun(@(x) x(1) ~= ';', lines));
    
    % Preallocate the cell array for key-value pairs
    kv_filters = cell(numLines, 2);
    
    % Initialize index for kv_filters
    kvIndex = 1;
    
    for i = 1:length(lines)
        line = strtrim(lines{i});
        if isempty(line) || line(1) == ';'  % Skip empty lines or comments
            continue;
        end

        % Split the line into key and value
        keyValue = strsplit(line, '=');
        
        % Ensure that the line contains exactly one '='
        if length(keyValue) ~= 2
            warning('Line "%s" does not contain exactly one "=". Skipping line.', line);
            continue;
        end
        
        key = strtrim(keyValue{1}); % Remove leading/trailing whitespace
        value = strtrim(keyValue{2}); % Remove leading/trailing whitespace
        
        % Parse and store the value
        if contains(value, ',')
            value = strsplit(value, ','); % Split comma-separated values into a cell array
            value = strtrim(value); % Trim each value in the cell array
            % Check if all are numeric and convert if possible
            if all(cellfun(@(x) ~isnan(str2double(x)), value))
                value = cellfun(@str2double, value); % Convert to numeric array
            end
        elseif isnan(str2double(value)) % Check if it's a single string value
            % Keep value as string
        else
            value = str2double(value); % Convert single numeric value
        end
        
        % Convert value to string if necessary
        if iscell(value)
            value = strjoin(cellfun(@num2str, value, 'UniformOutput', false), ',');
        elseif isnumeric(value)
            value = strjoin(arrayfun(@num2str, value, 'UniformOutput', false), ',');
        end
        
        if value == ';'
            continue;
        end
        
        % Store the key-value pair in the cell array
        kv_filters{kvIndex, 1} = key;
        kv_filters{kvIndex, 2} = value;
        kvIndex = kvIndex + 1;
    end
    
    % Trim the preallocated cell array to the actual number of entries
    kv_filters = kv_filters(1:kvIndex-1, :);
end
function parse_metadata_create_summary_doc(metadata, kv_filters, fileName, recordings_name)
    
    %GENERATE SUMMARY ACQUISITION INFO
    summary = metadata.Summary;
    keys = fieldnames(summary);
    excel_key_value_summary = cell(length(keys), 2);
    for i = 1:length(keys)
        key = keys{i};
        value = summary.(key);

        % Convert non-string values to a comma-separated string for uniformity
        if isnumeric(value)
            % Convert numeric arrays to comma-separated strings
            valueStr = num2str(value(:)', '%g,'); % Convert to row vector and format
            valueStr = valueStr(1:end-1); % Remove trailing comma
        elseif islogical(value)
            % Convert logical arrays to comma-separated strings
            valueStr = mat2str(value(:)'); % Convert to row vector
            valueStr = strrep(valueStr, ' ', ',');
            valueStr = valueStr(2:end-1); % Remove brackets
        elseif iscell(value)
            % Convert cell arrays to comma-separated strings
            valueStr = strjoin(cellfun(@num2str, value, 'UniformOutput', false), ',');
        elseif isstring(value)
            % Convert string arrays to comma-separated strings
            valueStr = strjoin(cellstr(value), ',');
        else
            valueStr = value; % Assume it's already a string
        end

        excel_key_value_summary{i, 1} = key;
        excel_key_value_summary{i, 2} = valueStr;
    end
    % APPEND kv_filters TO END OF excel_key_value_summary
    if size(kv_filters, 2) ~= 2
        error('kv_filters must have exactly 2 columns.');
    end

    if exist('kv_filters', 'var') && ~isempty(kv_filters)
        excel_key_value_summary = [excel_key_value_summary; kv_filters];
    end
    
    %EXTRACT MICROSCOPE SETTINGS FROM FIRST FRAMEKEY (settings for each acquired image in sequence)
    frameKeyPattern = 'Metadata_Default'; % Pattern for identifying FrameKey fields
    frameKeys = fieldnames(metadata);
    firstFrameKeyField = '';
    
    % Identify the first field that starts with the FrameKey pattern
    for idx1 = 1:length(frameKeys)
        if startsWith(frameKeys{idx1}, frameKeyPattern)
            firstFrameKeyField = frameKeys{idx1};
            break;
        end
    end
    
    % Iterate through fields of the frameKey structure
    if ~isempty(firstFrameKeyField)
        frameKey = metadata.(firstFrameKeyField);
        frameKeyFields = fieldnames(frameKey);
        
        %PROCESS ALL KEY:VALUE PAIRS IN FRAMEKEY
        for idx2 = 1:length(frameKeyFields)
            key = frameKeyFields{idx2};
            value = frameKey.(key);
            
            % Convert non-string values to a comma-separated string for uniformity
            if isnumeric(value)
                valueStr = num2str(value(:)', '%g,'); % Convert to row vector and format
                valueStr = valueStr(1:end-1); % Remove trailing comma
            elseif islogical(value)
                valueStr = mat2str(value(:)');
                valueStr = strrep(valueStr, ' ', ',');
                valueStr = valueStr(2:end-1); % Remove brackets
            elseif iscell(value)
                valueStr = strjoin(cellfun(@num2str, value, 'UniformOutput', false), ',');
            elseif isstring(value) || ischar(value)
                valueStr = value; % Assume it's already a string
            else
                valueStr = ''; % Default to an empty string if the type is unhandled
            end

            % Append the key-value pair to excel_key_value_summary
            excel_key_value_summary = [excel_key_value_summary; {key, valueStr}];
        end
    else
        warning('No FrameKey matching the pattern was found.');
    end    

    % Ensure all elements are strings [prior to Excel output]
    combinedCellArray = cell(size(excel_key_value_summary));
    for k = 1:numel(excel_key_value_summary)
        if isstruct(excel_key_value_summary{k})
            combinedCellArray{k} = '';
        else
            combinedCellArray{k} = excel_key_value_summary{k};
        end
    end
    
    %fileName PREVIOUSLY GENERATED [AND VERIFIED NOT EXIST, WHICH IS WHY
    %WE ARE HERE]
    try
        writecell(combinedCellArray, fileName);
    catch ME
        error('Failed to write to Excel file: %s\nError: %s', fileName, ME.message);
    end
end

function cleanName = sanitize_filename(name)
    % Remove or replace illegal characters from the filename
    illegalChars = {'<', '>', ':', '"', '/', '\', '|', '?', '*'};
    cleanName = name;
    for i = 1:length(illegalChars)
        cleanName = strrep(cleanName, illegalChars{i}, '_');
    end
    % Optionally, trim the filename length if it's too long
    maxLength = 255; % Maximum filename length in Windows
    if length(cleanName) > maxLength
        cleanName = cleanName(1:maxLength);
    end
end
function val = getenv_default(name, default_val)
    %GETENV_DEFAULT Return environment variable NAME, or DEFAULT_VAL if unset/empty.
    val = string(getenv(name));
    if strlength(val) == 0
        val = string(default_val);
    end
end
