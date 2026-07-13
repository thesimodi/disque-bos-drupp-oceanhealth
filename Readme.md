# Replication Package for Disque, Bos & Drupp (2025)

## Overview
The code in this replication package reproduces the results from Disque, Bos & Drupp (2025) using R and Matlab. The files in this repository run all of the code to generate the figures and tables in the paper. A replicator should expect the code to run for about 30 minutes (10 minutes excl. `4_Code/04_GARP_Test.qmd`).


## Data Availability and Provenance Statements
The paper uses data obtained from an online experiment. The experimental instructions are provided in the Supplementary Information and the experiment was programmed with oTree (Chen et al. 2016).

- We provide the raw experimental data as part of this replication package.
- We also provide the estimated preference parameters. While we also provide the corresponding Matlab code, replicators do not need to run the estimation code of this propiertary software to reproduce the results of the paper.

The data is available on Zenodo: https://doi.org/10.5281/zenodo.17521952


## Computational requirements

### Software Requirements
The following list indicates the software requirements.

- R 4.5.2
    - `renv` 1.1.5
        - `renv` provides a reproducible project environment. See `renv.lock` for the full list of used R packages and versions.

- Matlab (code was last run with Matlab Release 2024a)
    - `fminsearchbnd` Add-on
    - Parallelization toolkit

- Quarto 1.7.30

- Pandoc 3.7.0.1

Portions of the code use bash scripting and GNU Make, which may require Linux.


### Memory and Runtime Requirements 

The code was last run on a Lenovo ThinkPad T14 Gen 5 with Windows 11 version 24H2.
(32 GB RAM, AMD Ryzen 7 PRO 8840U 8-Core Processor 3.3 GHz).

Computations to reproduce the Figures and Tables took **around 30 minutes**.

**Caution**: The Matlab estimation `A_CES_Estimation_OHI.m` and the GARP test `04_GARP_Test.qmd` utilize parallelization and may require substantial CPU and RAM ressources. The same is true for the bootstrap test of the alpha parameter in `06_Figures.qmd` (toggled through 'run_alpha_bootstrap'). Should you encounter performance issues, consider reducing the number of workers used for parallelization in the respective code files. Note that this potentially increases the runtime to several hours. 


## Description of programs/code

- `06_Figures.qmd` generates all figures and table of the paper and includes any test statistics reported in the text.
- The other code files prepare the data and estimate the preference parameters.


## Instructions for replicators

1. Extract the contents of the data archive into the main project folder.
2. Open the project in your preferred R environment (e.g. RStudio, VSCode).
3. The project utilizes `renv` to facilitate reproducibility. Upon opening the project, a local environment should be instated automatically. Use `renv::restore()` to install the required packages listed in `renv.lock`.
4. Make sure that your Matlab is configured with a valid license. Skip `make matlab_estimation` if you do not have access to Matlab; we provide the estimated parameters in the data archive. To reproduce the Figures and Tables of the manuscript with your local environment, use GNU Make and run the following commands in a shell:
 
```
make data_prep
make matlab_estimation
make produce_figures
```

**Alternatively**, run the following commands directly in a shell:

```
# Prepare Data
quarto render 4_Code/01_Prep_Decision_Data.qmd
quarto render 4_Code/02_Prep_Quality_Controls.qmd
quarto render 4_Code/03_Prep_Survey_Data.qmd
quarto render 4_Code/04_GARP_Test.qmd

# Estimate Parameters in Matlab
matlab -batch "run 4_Code/Matlab_OHI/A_CES_Estimation_OHI.m; exit;"

# Produce Figures and Tables
quarto render 4_Code/05_Sample_Selection.qmd
quarto render 4_Code/06_Figures.qmd
```


## List of items and outputs reproduced
The provided code reproduces: All tables and figures in the paper (as output files) as well as any test statistics reported in the text (inside the code of `06_Figures.qmd`).

| Figure #                                                     | Output file                           |
| ------------------------------------------------------------ | ------------------------------------- |
| Figure 2: Summary of estimates and adjusted OHI scores       | `Figure_Panel2.pdf`                   |
| Figure 3: Decomposition of OHI score adjustments, substitutability effect and goal attainment inequality.       | `Figure_Panel3.pdf`                   |
| Figure 4: Heterogeneity in scores & preferences              | `Figure_Panel4.pdf`                   |
| SI Appendix Fig. S1: Sample countries                         | `SI_Appendix_FigS1.pdf`           |
| SI Appendix Fig. S2: Goal-pair-level estimates                | `SI_Appendix_FigS2.pdf`           |
| SI Appendix Fig. S3: OHI scores before and after adjustment   | `SI_Appendix_FigS3.pdf`           |
| SI Appendix Fig. S4: Sensitivity analyses                     | `SI_Appendix_FigS4.pdf`           |
| SI Appendix Fig. S5: Heterogeneity analysis of perceived OHI goal importance       | `SI_Appendix_FigS5.pdf`                   |
| SI Appendix Fig. S6: Heterogeneity analysis of OHI adjustment | `SI_Appendix_FigS6.pdf`           |
| SI Appendix Fig. S7: Correlational analysis of preference parameters and OHI scores | `SI_Appendix_FigS7.pdf`           |
| SI Appendix Fig. S8: Summary of estimates and adjusted OHI scores (sample and aggregation sensitivity analyses) | `SI_Appendix_FigS8.pdf`           |
| SI Appendix Fig. S9: Summary of estimates and adjusted OHI scores (estimation uncertainty, Krinsky-Robb)  | `SI_Appendix_FigS9.pdf`           |
| SI Appendix Fig. S10: Summary of estimates and adjusted OHI scores (sampling uncertainty, bootstrap)      | `SI_Appendix_FigS10.pdf`          |
| SI Appendix Fig. S11: Sensitivity analysis for different percentiles of the substitutability preferences  | `SI_Appendix_FigS11.pdf`          |

| Table #                                                      | Output file                      |
| ------------------------------------------------------------ | -------------------------------- |
| SI Appendix Tab. S1: Descriptive statistics                         | `SI_Appendix_TabS1.tex`           |
| SI Appendix Tab. S2: Summary of estimates & reported goal scores                | `SI_Appendix_TabS2.tex`           |