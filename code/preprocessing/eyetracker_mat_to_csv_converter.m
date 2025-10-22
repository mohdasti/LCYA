function eyetracker_mat_to_csv_converter(mat_file_path, output_dir)
% EYETRACKER_MAT_TO_CSV_CONVERTER Converts MATLAB eyetracker data files to CSV format
%
% This script converts task-specific MATLAB output files (.mat) from the 
% LC-YA study to CSV format for statistical analysis in R. It automatically
% detects the task type and subject ID from the filename and applies the
% appropriate conversion logic.
%
% Usage:
%   eyetracker_mat_to_csv_converter(mat_file_path, output_dir)
%
% Inputs:
%   mat_file_path - Full path to the .mat file to convert
%   output_dir    - Directory where CSV files will be saved (optional)
%                   If not provided, saves to same directory as .mat file
%
% Example:
%   eyetracker_mat_to_csv_converter('subject74_Aoddball_session1_run1.mat', './csv_output/')
%
% Supported Tasks:
%   - ADT (Auditory Discrimination Task): Aoddball files
%   - VDT (Visual Discrimination Task): Voddball files
%   - CDT (Change Detection Task): CD files
%   - MST (Mnemonic Similarity Task): MST files
%
% Output Format:
%   - ADT_S{subject_id}.csv: Auditory task behavioral data
%   - VDT_S{subject_id}.csv: Visual task behavioral data
%   - CDT_S{subject_id}.csv: Change detection task behavioral data
%   - MST_S{subject_id}.csv: MST encoding phase data
%   - MST_test_S{subject_id}.csv: MST test phase data
%
% Author: LC-YA Study Team
% Date: October 2024
% Version: 1.0

%% Input Validation and Setup
if nargin < 1
    error('eyetracker_mat_to_csv_converter:InvalidInput', ...
          'At least one input argument (mat_file_path) is required.');
end

if nargin < 2
    [file_dir, ~, ~] = fileparts(mat_file_path);
    output_dir = file_dir;
end

% Check if file exists
if ~exist(mat_file_path, 'file')
    error('eyetracker_mat_to_csv_converter:FileNotFound', ...
          'File not found: %s', mat_file_path);
end

% Create output directory if it doesn't exist
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% Parse Filename to Extract Task Type and Subject ID
[~, filename, ~] = fileparts(mat_file_path);
fprintf('Processing file: %s\n', filename);

% Extract subject ID
subject_match = regexp(filename, 'subject(\d+)', 'tokens');
if isempty(subject_match)
    error('eyetracker_mat_to_csv_converter:InvalidFilename', ...
          'Cannot extract subject ID from filename: %s', filename);
end
subject_id = str2double(subject_match{1}{1});
fprintf('  Subject ID: %d\n', subject_id);

% Determine task type
if contains(filename, 'Aoddball')
    task_type = 'ADT';
    fprintf('  Task Type: Auditory Discrimination Task (ADT)\n');
elseif contains(filename, 'Voddball')
    task_type = 'VDT';
    fprintf('  Task Type: Visual Discrimination Task (VDT)\n');
elseif contains(filename, '_CD_')
    task_type = 'CDT';
    fprintf('  Task Type: Change Detection Task (CDT)\n');
elseif contains(filename, 'MST')
    task_type = 'MST';
    fprintf('  Task Type: Mnemonic Similarity Task (MST)\n');
else
    error('eyetracker_mat_to_csv_converter:UnknownTask', ...
          'Cannot determine task type from filename: %s', filename);
end

%% Load MATLAB Data
fprintf('  Loading data...\n');
data = load(mat_file_path);

%% Convert Based on Task Type
switch task_type
    case 'ADT'
        convert_ADT(data, subject_id, output_dir);
    case 'VDT'
        convert_VDT(data, subject_id, output_dir);
    case 'CDT'
        convert_CDT(data, subject_id, output_dir);
    case 'MST'
        convert_MST(data, subject_id, output_dir);
end

fprintf('  Conversion complete!\n\n');

end

%% Task-Specific Conversion Functions

function convert_ADT(data, subject_id, output_dir)
% Convert Auditory Discrimination Task (ADT) data to CSV
%
% Output columns:
%   1. Subject ID
%   2. Accuracy (iscorr)
%   3. Response (ActualResponse)
%   4. Stimulus Level (Oddball_level)
%   5. Grip Level (grip_level)
%   6. Response Duration
%   7. Confidence Rating
%   8. Is Oddball (isoddball)

    % Calculate response duration
    ResponseDuration = data.Resp1EndTimeP_SBP - data.Resp1StartTimeP;
    
    % Extract grip level
    grip_level = repmat(data.gf_trPer, 1);
    
    % Extract stimulus level
    Oddball_level = data.StimLev(data.mixtr(:,1));
    
    % Get number of trials
    n_trials = length(data.iscorr);
    
    % Assemble output matrix
    ADT_csv_output = [
        transpose(repelem(subject_id, n_trials)), ...
        transpose(data.iscorr), ...
        transpose(data.ActualResponse), ...
        transpose(Oddball_level), ...
        transpose(grip_level), ...
        transpose(ResponseDuration), ...
        transpose(data.ConfidenceRate), ...
        transpose(data.isoddball)
    ];
    
    % Write to CSV
    output_file = fullfile(output_dir, sprintf('ADT_S%d.csv', subject_id));
    writematrix(ADT_csv_output, output_file);
    fprintf('    Saved: %s (%d trials)\n', output_file, n_trials);
end

function convert_VDT(data, subject_id, output_dir)
% Convert Visual Discrimination Task (VDT) data to CSV
%
% Output columns:
%   1. Subject ID
%   2. Accuracy (iscorr)
%   3. Response (ActualResponse)
%   4. Stimulus Level (Oddball_level)
%   5. Grip Level (grip_level)
%   6. Response Duration
%   7. Confidence Rating
%   8. Is Oddball (isoddball)

    % Calculate response duration
    ResponseDuration = data.Resp1EndTimeP_SBP - data.Resp1StartTimeP;
    
    % Extract grip level
    grip_level = repmat(data.gf_trPer, 1);
    
    % Extract stimulus level
    Oddball_level = data.StimLev(data.mixtr(:,1));
    
    % Get number of trials
    n_trials = length(data.iscorr);
    
    % Assemble output matrix
    VDT_csv_output = [
        transpose(repelem(subject_id, n_trials)), ...
        transpose(data.iscorr), ...
        transpose(data.ActualResponse), ...
        transpose(Oddball_level), ...
        transpose(grip_level), ...
        transpose(ResponseDuration), ...
        transpose(data.ConfidenceRate), ...
        transpose(data.isoddball)
    ];
    
    % Write to CSV
    output_file = fullfile(output_dir, sprintf('VDT_S%d.csv', subject_id));
    writematrix(VDT_csv_output, output_file);
    fprintf('    Saved: %s (%d trials)\n', output_file, n_trials);
end

function convert_CDT(data, subject_id, output_dir)
% Convert Change Detection Task (CDT) data to CSV
%
% Output columns:
%   1. Subject ID
%   2. Accuracy (iscorr)
%   3. Response (ActualResponse)
%   4. Orientation Change (degrees)
%   5. Grip Level (grip_level)
%   6. Response Duration
%   7. Confidence Rating

    % Calculate response duration
    ResponseDuration = data.Resp1EndTimeP_SBP - data.Resp1StartTimeP;
    
    % Extract and recode orientation (-1 or +1)
    orientation = data.mixtr(:,2);
    orientation(orientation == 1) = -1;
    orientation(orientation == 2) = 1;
    
    % Extract and recode degrees (0, 5, 20, 45, 90)
    degrees = data.mixtr(:,3);
    degrees(degrees == 1) = 0;
    degrees(degrees == 2) = 6;   % Intentional: prevents collision with 90
    degrees(degrees == 3) = 20;
    degrees(degrees == 4) = 45;
    degrees(degrees == 5) = 90;
    
    % Calculate final orientation change
    degrees = orientation .* degrees;
    degrees = transpose(degrees);
    
    % Extract and recode grip level
    grip_level = data.mixtr(:,5);
    grip_level(grip_level == 1) = 0.4;
    grip_level(grip_level == 2) = 0.05;
    grip_level = transpose(grip_level);
    
    % Get number of trials
    n_trials = length(data.iscorr);
    
    % Assemble output matrix
    CDT_csv_output = [
        transpose(repelem(subject_id, n_trials)), ...
        transpose(data.iscorr), ...
        transpose(data.ActualResponse), ...
        degrees, ...
        grip_level, ...
        transpose(ResponseDuration), ...
        transpose(data.ConfidenceRate)
    ];
    
    % Write to CSV
    output_file = fullfile(output_dir, sprintf('CDT_S%d.csv', subject_id));
    writematrix(CDT_csv_output, output_file);
    fprintf('    Saved: %s (%d trials)\n', output_file, n_trials);
end

function convert_MST(data, subject_id, output_dir)
% Convert Mnemonic Similarity Task (MST) data to CSV
%
% Generates two output files:
%   1. MST_S{id}.csv: Encoding phase data
%   2. MST_test_S{id}.csv: Test phase data
%
% Encoding phase columns:
%   1. Subject ID
%   2. Response (ActualResponse)
%   3. Indoor/Outdoor (indoor)
%   4. Grip Level (grip_level)
%   5. Response Duration (EncodResponseDuration)
%   6. Image Set (Image_set_encode)
%   7. Image Number (Image_number_encode)
%
% Test phase columns:
%   1. Subject ID
%   2. Response (ActualResponse_test)
%   3. Image Type (Target/Lure/Foil)
%   4. Image Number (image_number_test)
%   5. Accuracy (test_iscorr)
%   6. Response Duration (TestResponseDuration)
%   7. Confidence Response (ActualResponse_conf)
%   8. Confidence Report Duration (ConfidenceReportDuration)

    % --- Encoding Phase ---
    EncodResponseDuration = data.Resp1EndTimeP_SBP - data.Resp1StartTimeP;
    
    % Extract and recode grip level
    grip_level = data.gf_trPer;
    grip_level(grip_level == 0.4000) = 0.4;
    grip_level(grip_level == 0.0500) = 0.05;
    
    % Extract image numbers for encoding phase
    Image_number_encode = zeros(length(data.mixtr), 1);
    for trial = 1:length(data.mixtr)
        Image_number_encode(trial) = data.RImsets(data.mixtr(trial,1), data.mixtr(trial,2));
    end
    
    % Extract image set for encoding phase
    Image_set_encode = data.mixtr(:,1);
    Image_set_encode = transpose(Image_set_encode);
    
    % Get number of encoding trials
    n_encode_trials = length(data.mixtr);
    
    % Assemble encoding output matrix
    MST_encode_csv_output = [
        transpose(repelem(subject_id, n_encode_trials)), ...
        transpose(data.ActualResponse), ...
        transpose(data.indoor), ...
        transpose(grip_level), ...
        transpose(EncodResponseDuration), ...
        Image_set_encode, ...
        transpose(Image_number_encode)
    ];
    
    % Write encoding phase CSV
    output_file_encode = fullfile(output_dir, sprintf('MST_S%d.csv', subject_id));
    writematrix(MST_encode_csv_output, output_file_encode);
    fprintf('    Saved: %s (%d trials)\n', output_file_encode, n_encode_trials);
    
    % --- Test Phase ---
    TestResponseDuration = data.testEndTime_SBP - data.testStimStartTime;
    ConfidenceReportDuration = data.testConfEndTimeP_SBP - data.testConfStartTimeP;
    
    % Extract image numbers for test phase
    image_number_test = zeros(length(data.mixtr2), 1);
    for xtrial = 1:length(data.mixtr2)
        image_number_test(xtrial) = data.RImsets(data.mixtr2(xtrial,1), data.mixtr2(xtrial,2));
    end
    
    % Extract image type (Target, Lure, Foil)
    image_type_test = data.mixtr2(:,1);
    image_type_test = transpose(image_type_test);
    
    % Get number of test trials
    n_test_trials = length(data.mixtr2);
    
    % Assemble test output matrix
    MST_test_csv_output = [
        transpose(repelem(subject_id, n_test_trials)), ...
        transpose(data.ActualResponse_test), ...
        image_type_test, ...
        transpose(image_number_test), ...
        transpose(data.test_iscorr), ...
        transpose(TestResponseDuration), ...
        transpose(data.ActualResponse_conf), ...
        transpose(ConfidenceReportDuration)
    ];
    
    % Write test phase CSV
    output_file_test = fullfile(output_dir, sprintf('MST_test_S%d.csv', subject_id));
    writematrix(MST_test_csv_output, output_file_test);
    fprintf('    Saved: %s (%d trials)\n', output_file_test, n_test_trials);
end

