# Spending Modelling — Jamaica case

Standalone slice of `2025-05_spendingModelling` for the Jamaica case
presentation (`docs/2026-06_Jamaica-case`). It carries only the models the
deck plots and the drivers/scripts needed to (re)run them and rebuild the
charts.

## What's included

Ten Dynare model variants (`models/`):

- **Jamaica** (EM parameters + Jamaica efficiency gaps, `JAM_efficiency.macro`):
  `JAM_Model_HumanCapital_{epsiig, epsicge, epsiigeff30y, epsicgeeff30y}`
- **EM comparators** (used by the EM baseline charts in the deck):
  `EM_Model_HumanCapital_{epsiig, epsicge, epsiigeff25y, epsiigeff30y,
  epsicgeeff25y, epsicgeeff30y}`

Pre-computed results (`models/<name>/Output/<name>_results.mat`) are bundled,
so the charts can be rebuilt without re-running MATLAB/Dynare.

## Layout

```
drivers/            MATLAB drivers (runModel, runSimulExport, ...)
models/             10 model bundles + shared templates/macros
+utils/, +environment/   shared MATLAB packages, shockDict/varDict
docs/
  csvFiles/         figureNumbers.csv / figureNumbers_yearly.csv (model exports)
  2026-06_Jamaica-case/
    pyScripts/      four Plotly chart scripts + config
    latex/          presentation.tex + figures/ (+ built presentation.pdf)
```

## Reproducing the presentation

1. **Run the models** (MATLAB + Dynare 5.5 + IRIS, paths in
   `+utils/+call/paths.m`):

   ```matlab
   run('iniProject.m')
   run('drivers/runModel.m')        % regenerates models/<name>/Output/*.mat
   ```

   `runModel.m` runs the 10 variants listed in its `modelList`. A benign
   exit-time segfault after all models complete is expected.

2. **Export the figure numbers** (MATLAB + IRIS):

   ```matlab
   run('drivers/runSimulExport.m')  % writes docs/csvFiles/figureNumbers*.csv
   ```

   It iterates the models in `+environment/csvFiles/shockDict.csv` (the same
   10) and writes the quarterly and yearly CSVs the chart scripts read.

3. **Build the charts** (Python: pandas, plotly, kaleido):

   ```sh
   cd docs/2026-06_Jamaica-case/pyScripts
   python plotReallocationEMLines.py
   python plotEfficiencyEMLines.py
   python plotCombinedEMLines.py
   python plotCombinedJAMLines.py
   ```

   PNG/HTML/CSV land in `../latex/figures/`.

4. **Build the deck**: `pdflatex` (twice) on
   `docs/2026-06_Jamaica-case/latex/presentation.tex`.

> The deck also includes `reallocationEM_yd.png` and `efficiencyEM_yd.png`
> (without the `_lines` suffix). These are pre-rendered and shipped as static
> files — they are not produced by the four Python scripts above.

## Relationship to the parent repo

This is a copy; the Jamaica and EM models remain in `2025-05_spendingModelling`
too. The full 48-model `modelList` and `shockDict` live there; here both are
trimmed to the 10 deck models.
