# Instructions
The `submit_condor.sh` script is used to submit jobs to HTCondor: here are some instructions on how to run it.

## Before you run
1. Always run this script from within the `quickFit/submit_condor/` directory.

2. There is no need for you to create folders to store the outputs, the script does that automatically. If they don't already exist, `submit_condor.sh` creates the following directories: `out/`,`err/`,`log/`,`../output/`.

3. Any file inside a folder (or softlink) named `workspace/` (located in `quickFit/`) will be accessible by the command you are submitting to HTCondor. I you want to use a file, use its relative path: `workspace/path/to/file`. If you want to use an input file that is not stored in the `workspace/` folder, use the `-i, --input` option.

4. The quickFit output is copied to the `quickFit/output/` folder when the job ends. The full standard output can be found at `quickFit/submit_condor/out/`, but a named copy can be saved anywhere using the `-o, --output` option.

## How to run
From within `submit_condor/` run:
```
bash submit_condor.sh -c "<COMMAND>" [-i <INPUT> -o <OUTPUT> -b <BLIND> -h]
```
Options:
* `-c, --command "COMMAND"` (required): command to be submitted to HTCondor.

* `-i, --input INPUT` (optional): input file name (path relative to `quickFit/` directory). N.B. all files inside the directory (or softlink) `quickFit/workspace` are by default accessible by COMMAND.

* `-o, --output OUTPUT` (optional): path to a txt file where the standard output of COMMAND will be saved. Use .txt extension and path relative to quickFit/.

* `-b, --blind BLIND` (optional): used for omitting from the standard output txt file any line containing the word given as argument. Multiple parameters can be blinded if separated by a comma e.g. `-b mu_Zboson,mu_Higgs`.

* `-h, --help` (optional): display this help and exit

## Examples
### ex.1
```
bash submit_condor.sh -c "quickFit -f workspace/hbbj/CRttbar/CRttbar_model_asimov_tag.root -d combData -p mu_ttbar=1_0_2 -o output/output_name.root --savefitresult 1 --saveWS true --ssname quickfit --minStrat 2 --minTolerance 1e-4 --hesse 1 --minos 3 -n gamma_*"
```
Minimal example where only the required option `-c` is used. This command submits a CRttbar-only fit which uses as input a file stored in the default directory (or softlink) `quickFit/workspace`.
### ex.2
```
bash submit_condor.sh -c "quickFit -f workspace/hbbj/SR/SR_model_data_tag.root -d combData -p mu_Zboson=1_-3_5,mu_Higgs=1,mu_ttbar=1_0.5_1.5 -o output/output_name.root --savefitresult 1 --saveWS true --ssname quickfit --minStrat 1 --minTolerance 1e-4 --hesse 1 --minos 1 -n gamma_*,g_srl,h_sr*" -b mu_Zboson -o output/output_name.txt
```
This command submits a SR combined fit whose input file is in the default `quickFit/workspace/` directory (or softlink). The standard output txt file with blinded `mu_Zboson` is saved at `quickFit/output/output_name.txt`.
### ex.3
```
bash submit_condor.sh -c "quickFit -f CRttbar_model_asimov_tag.root -d combData -p mu_ttbar=1_0_2 -o output/output_name.root --savefitresult 1 --saveWS true --ssname quickfit --minStrat 2 --minTolerance 1e-4 --hesse 1 --minos 3 -n gamma_*" -i ../xmlAnaWSBuilder/workspace/hbbj/CRttbar/CRttbar_model_asimov_tag.root -o output/output_name.txt
```
This command submits a CRttbar-only fit whose input file is made available via the `-i` option. The unblinded standard output txt file is saved at `quickFit/output/output_name.txt`.