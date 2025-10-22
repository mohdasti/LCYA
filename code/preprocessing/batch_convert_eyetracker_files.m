function batch_convert_eyetracker_files(input_dir, output_dir)
% BATCH_CONVERT_EYETRACKER_FILES Batch converts all eyetracker .mat files to CSV
%
% This script processes all task-specific MATLAB output files (.mat) in a 
% directory and converts them to CSV format for statistical analysis in R.
% It uses the eyetracker_mat_to_csv_converter function for each file.
%
% Usage:
%   batch_convert_eyetracker_files(input_dir, output_dir)
%
% Inputs:
%   input_dir  - Directory containing .mat files to convert
%   output_dir - Directory where CSV files will be saved (optional)
%                If not provided, saves to input_dir/csv_output/
%
% Example:
%   batch_convert_eyetracker_files('./ParticipantsOutput/', './csv_output/')
%
% The script will:
%   1. Search for all .mat files in input_dir
%   2. Filter for task-specific files (ADT, VDT, CDT, MST)
%   3. Convert each file to CSV format
%   4. Generate a summary report
%
% Author: LC-YA Study Team
% Date: October 2024
% Version: 1.0

%% Input Validation and Setup
if nargin < 1
    error('batch_convert_eyetracker_files:InvalidInput', ...
          'At least one input argument (input_dir) is required.');
end

if nargin < 2
    output_dir = fullfile(input_dir, 'csv_output');
end

% Check if input directory exists
if ~exist(input_dir, 'dir')
    error('batch_convert_eyetracker_files:DirNotFound', ...
          'Input directory not found: %s', input_dir);
end

% Create output directory if it doesn't exist
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% Find All Task-Specific .mat Files
fprintf('====================================================\n');
fprintf('LC-YA Eyetracker Data Batch Conversion\n');
fprintf('====================================================\n\n');
fprintf('Input Directory:  %s\n', input_dir);
fprintf('Output Directory: %s\n\n', output_dir);

% Get all .mat files
all_mat_files = dir(fullfile(input_dir, '*.mat'));

% Filter for task-specific files
task_patterns = {'Aoddball', 'Voddball', '_CD_', 'MST'};
task_files = {};

for i = 1:length(all_mat_files)
    filename = all_mat_files(i).name;
    for j = 1:length(task_patterns)
        if contains(filename, task_patterns{j})
            task_files{end+1} = fullfile(input_dir, filename);
            break;
        end
    end
end

n_files = length(task_files);
fprintf('Found %d task-specific .mat files to convert:\n', n_files);

if n_files == 0
    fprintf('No task-specific .mat files found in directory.\n');
    fprintf('Looking for files containing: Aoddball, Voddball, _CD_, or MST\n');
    return;
end

%% Initialize Tracking Variables
conversion_stats = struct();
conversion_stats.total = n_files;
conversion_stats.successful = 0;
conversion_stats.failed = 0;
conversion_stats.failed_files = {};
conversion_stats.by_task = struct('ADT', 0, 'VDT', 0, 'CDT', 0, 'MST', 0);

%% Process Each File
fprintf('\n----------------------------------------------------\n');
fprintf('Beginning conversion process...\n');
fprintf('----------------------------------------------------\n\n');

start_time = tic;

for i = 1:n_files
    mat_file = task_files{i};
    [~, filename, ~] = fileparts(mat_file);
    
    fprintf('[%d/%d] Processing: %s\n', i, n_files, filename);
    
    try
        % Convert file
        eyetracker_mat_to_csv_converter(mat_file, output_dir);
        
        % Update statistics
        conversion_stats.successful = conversion_stats.successful + 1;
        
        % Track by task type
        if contains(filename, 'Aoddball')
            conversion_stats.by_task.ADT = conversion_stats.by_task.ADT + 1;
        elseif contains(filename, 'Voddball')
            conversion_stats.by_task.VDT = conversion_stats.by_task.VDT + 1;
        elseif contains(filename, '_CD_')
            conversion_stats.by_task.CDT = conversion_stats.by_task.CDT + 1;
        elseif contains(filename, 'MST')
            conversion_stats.by_task.MST = conversion_stats.by_task.MST + 1;
        end
        
    catch ME
        % Handle conversion error
        conversion_stats.failed = conversion_stats.failed + 1;
        conversion_stats.failed_files{end+1} = filename;
        
        fprintf('    ERROR: %s\n', ME.message);
        fprintf('    Skipping file and continuing...\n\n');
    end
end

elapsed_time = toc(start_time);

%% Generate Summary Report
fprintf('\n====================================================\n');
fprintf('CONVERSION SUMMARY\n');
fprintf('====================================================\n\n');

fprintf('Total Files Processed:     %d\n', conversion_stats.total);
fprintf('Successfully Converted:    %d\n', conversion_stats.successful);
fprintf('Failed Conversions:        %d\n', conversion_stats.failed);
fprintf('\nBy Task Type:\n');
fprintf('  ADT (Auditory):          %d files\n', conversion_stats.by_task.ADT);
fprintf('  VDT (Visual):            %d files\n', conversion_stats.by_task.VDT);
fprintf('  CDT (Change Detection):  %d files\n', conversion_stats.by_task.CDT);
fprintf('  MST (Memory):            %d files\n', conversion_stats.by_task.MST);
fprintf('\nTotal Processing Time:     %.2f seconds\n', elapsed_time);
fprintf('Average Time per File:     %.2f seconds\n', elapsed_time/n_files);

if conversion_stats.failed > 0
    fprintf('\n----------------------------------------------------\n');
    fprintf('FAILED CONVERSIONS:\n');
    fprintf('----------------------------------------------------\n');
    for i = 1:length(conversion_stats.failed_files)
        fprintf('  %d. %s\n', i, conversion_stats.failed_files{i});
    end
end

fprintf('\n====================================================\n');
fprintf('Output files saved to: %s\n', output_dir);
fprintf('====================================================\n\n');

%% Save Summary Report to Text File
report_file = fullfile(output_dir, 'conversion_summary.txt');
fid = fopen(report_file, 'w');

fprintf(fid, '====================================================\n');
fprintf(fid, 'LC-YA EYETRACKER DATA CONVERSION SUMMARY\n');
fprintf(fid, '====================================================\n\n');
fprintf(fid, 'Conversion Date: %s\n\n', datestr(now));
fprintf(fid, 'Input Directory:  %s\n', input_dir);
fprintf(fid, 'Output Directory: %s\n\n', output_dir);
fprintf(fid, 'Total Files Processed:     %d\n', conversion_stats.total);
fprintf(fid, 'Successfully Converted:    %d\n', conversion_stats.successful);
fprintf(fid, 'Failed Conversions:        %d\n', conversion_stats.failed);
fprintf(fid, '\nBy Task Type:\n');
fprintf(fid, '  ADT (Auditory):          %d files\n', conversion_stats.by_task.ADT);
fprintf(fid, '  VDT (Visual):            %d files\n', conversion_stats.by_task.VDT);
fprintf(fid, '  CDT (Change Detection):  %d files\n', conversion_stats.by_task.CDT);
fprintf(fid, '  MST (Memory):            %d files\n', conversion_stats.by_task.MST);
fprintf(fid, '\nTotal Processing Time:     %.2f seconds\n', elapsed_time);
fprintf(fid, 'Average Time per File:     %.2f seconds\n', elapsed_time/n_files);

if conversion_stats.failed > 0
    fprintf(fid, '\n----------------------------------------------------\n');
    fprintf(fid, 'FAILED CONVERSIONS:\n');
    fprintf(fid, '----------------------------------------------------\n');
    for i = 1:length(conversion_stats.failed_files)
        fprintf(fid, '  %d. %s\n', i, conversion_stats.failed_files{i});
    end
end

fclose(fid);
fprintf('Summary report saved to: %s\n\n', report_file);

end

