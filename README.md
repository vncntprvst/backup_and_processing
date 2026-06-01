# **Neurodata backup and launch scripts**

## Overview
The files in **backup-scripts** are intended to be installed on instrumentation/acquisition computers for regular/systematic backups to a local or remote server.
Scripts in **metadata_extraction** and **processing** (which contains **Remote** trigger scripts and **NWB** conversion-prep scripts) are useful for subsequent processing, such as submission to a computing cluster and NWB conversion prep.

> Part of the U19 Data Science Core umbrella, [U19-data-management-and-processing](https://github.com/vncntprvst/U19-data-management-and-processing).

## Workflow
The general workflow is as follows:
1. **Assemble the dataset**: Collect data and metadata from the acquisition computer, such as raw ephys data, video, and task data.
   - Metadata extraction can be mostly automatized. However, the user must provide information about the experiment, such as subject ID, session number, and other relevant details. This information can be stored either in a JSON file, an Excel file, or any other format that can be easily parsed, or online (e.g., a Google Sheet, or a lab notebook with a web API). Metadata extraction scripts can also be run on the remote server after the data transfer, but with the caveat that the user must ensure the metadata is available in a format that can be parsed by the scripts.
   - The data should ideally be organized in a structured manner, such as by subject and session.
   - Conversion to NWB format may be done at this stage, or later. 
2. **Backup the data**: Regularly back up data from the acquisition computer to a local or remote server.
   - This can be done using tools like `rsync`, `SyncBackPro`, or `WinSCP`.
   - The backup should include all relevant data, such as raw ephys data, video files, and task data.
   - The backup solution can be configured to run automatically at regular intervals (e.g., nightly).
3. **Data processing**: After backup, run scripts to process the data, such as converting to NWB format, spike sorting, or behavior tracking.
   - This can be done using MATLAB, Python, or any other programming language that supports the required libraries and tools.
   - The processing scripts can be run on the acquisition computer or on a remote server, depending on the setup and available resources.
   - The processed data should also be backed up, and the metadata should be updated accordingly.

This is a work in progress. If you have additional scripts that may be useful in processing (automatic calculations, file transfer, etc), and wish to share with U19 consortium, please contact: drinehart@ucsd.edu.

It helps to organize datasets by user (if a shared computer) and by project. E.g.:  
```bash
├───User1
│   ├───MyProject
│   │   ├───Subject_1
│   │   │   ├───Session_1
│   │   │   ├───Session_2
│   │   │   └───Session_3
│   │   ├───Subject_2
│   │   │   ├───Session_1
│   └───MyOtherProject
│   │   ├───Subject_1
│   │   │   ├───Session_1
│   │   │   ├───Session_2
|───User2
│   ├───MyProject
│   │   ├───Subject_1
│   │   │   ├───Session_1
│   │   │   ├───Session_2
│   │   ├───Subject_2
│   │   │   ├───Session_1
│   │   │   ├───Session_2
│   │   │   ├───Session_3
```
Similarly, it is suggested to organize datasets within each session by modality and processing step (e.g., raw, processed, NWB, etc).  E.g:
```bash
<session_folder path>
├── processed_data
│   ├── spike_sorting_output
│   └── tracking_output
├── raw_ephys_data
│   ├── data_description.json
│   ├── Record Node 101
│   ├── subject.json
├── raw_video_data
│   ├── Basler_acA640-750um__24441171__20250401_165928367.mp4
│   └── Basler_acA640-750um__24441215__20250401_165931525.mp4
└── task_data
    └── Bpod
```

## Installation
1. GitHub clone [TBD](https://github.com/update_this.git) to a local directory (e.g., `C:\Data\Backups`).

```bash
cd C:\Data\Backups
git clone https://github.com/vncntprvst/backup_and_processing.git
```

2. Set up a backup solution
   See documentation files.  
   Options include:
- [Use rsync from Windows terminal](documentation/Use%20rsync%20from%20Windows%20terminal.md)
- [Set up SyncBackPro](documentation/Set%20up%20SyncBackPro.md)
- [Set up WinSCP](documentation/Set%20up%20WinSCP.md)


3. Verify which parsing script will be run before/after transfer.

4. Edit lunch scripts
On Windows, using a text editor, edit `launch.bat` or `launch_remote.bat` to run the correct parsing command, as appropriate.
      - **Note**: `launch.bat` example runs a MATLAB script on the acquisition computer.
      - **N.B.** `launch_remote_py.bat` runs `trigger.py` (see additional notes in [README-trigger.md](README-trigger.md)).
      - **N.B.2** `launch_remote_ps.bat` runs `trigger.ps1` (see additional notes in [README-trigger_ps.md](README-trigger_ps.md)).


+ See also [README-ssh_windows_linux.md](README-ssh_windows_linux.md) to setup password-less SSH from Windows to Linux
  

## Post-acquisition server (linux):

In example above where post-acquisition will occur, ensure script exists (Matlab or python).  
This step should include any formatting/analysis required after acquisition as well as meta-data extraction into NWB recordings files (Excel/csv)

Example bash script for launching server-side scripts: post-acquisition/post-acquire.sh

## Features

- Nightly transfer of data from acquisition computer to local storage computer
- Email notification of transferred files
- Ability to integrate with other applications (compute/interim calcs, appending to lab notebook/database, conversion to NWB format)


## Contribute

[Issue Tracker] (https://github.com/USArhythms/pipeline/issues)

[Source Code] (https://github.com/USArhythms/pipeline)

## Support

If you are having issues or questions; or have code to contribute, please let me know.
Duane Rinehart
drinehart[at]ucsd.edu

## License

The project is licensed under the [MIT license](https://mit-license.org/).

---
Last update: 07-Jun-2025
