# Measurement and model evaluation

## ECG comparison

The [supplied validation script](ppg_ecg_batch_validate_edge_offset_sweep.py) compares app PPG exports with OpenSignals ECG recordings. The [example figure](../images/compare_app_to_monitor.png) illustrates a lab comparison; no aggregate ECG comparison results accompany this repository. It supports describing laboratory evaluation, rather than a claim of clinical certification or demonstrated treatment efficacy.

### Synchronization and peak extraction

Recording start timestamps are converted to UTC and used to select the same analysis window. The script filters ECG with a second-order 5–35 Hz Butterworth filter, standardizes it, and detects R-peaks with a minimum 0.45-second separation. App peaks are read from the exported analysis rather than redetected by this script.

The supplied script currently selects **4.5–24.5 seconds (20 seconds)** of app time. The supplied figure is labeled “24s”; it is retained as provided and should not be treated as proof of the current script’s window configuration.

### Interval comparison

For consecutive peak times, the interval is Δt = tᵢ₊₁ − tᵢ and the corresponding heart rate is **hᵢ = 60 / Δt**. ECG RR and PPG pulse intervals are compared rather than requiring their absolute peaks to coincide.

Dynamic programming preserves sequence order while allowing skipped intervals. Each match costs the absolute BPM difference; skipping an interval costs **8 BPM** in the alignment objective. An edge sweep considers dropping up to two initial and one final interval independently from each signal.

For each candidate, the selection score is:

**within-5 percentage − 10 × MAE + 5 × Pearson r**

The correlation term is used when defined. Among candidates at or above the pair’s mean selection score, the script prioritizes ECG coverage, then lower MAE, app coverage, and penalized MAE. Because alignment and edge selection use the same comparison data, matched-only errors need to be read alongside coverage and penalized results.

### Reported calculations

With matched interval errors **eᵢ = h_app,i − h_ECG,i**:

- **Bias:** mean(e).
- **MAE:** mean(|e|), in BPM.
- **RMSE:** √mean(e²), in BPM.
- **Bland–Altman limits of agreement:** bias ± 1.96 × sample standard deviation of e.
- **Within 5 BPM:** percentage of matched intervals with |e| ≤ 5.
- **Pearson correlation:** association between matched interval heart rates, where defined.

Unmatched and edge-dropped intervals receive a **20 BPM error** in penalized error summaries. Coverage, interval sensitivity, positive predictive value, and F1 also account for omitted intervals. These are interval-alignment metrics, not clinical diagnostic sensitivity. The script exports per-recording results, aggregate summaries, and diagnostic plots; numerical ECG agreement claims should be based on those outputs.

## Signal-quality model

The training project uses labeled ten-second segments from **BUT PPG (Brno University of Technology Smartphone PPG Database)** and **BIDMC PPG and Respiration Dataset**. The saved run contains **2,592 segments: 1,835 training, 378 validation, and 379 test**. These are segment counts, not participant counts.

The model combines a 64-dimensional waveform embedding with a 64-dimensional peak-branch embedding. The peak branch combines a CNN over a binary peak mask with a small network over five statistics: peak count, mean interval, mean heart rate, interval standard deviation, and RMSSD. A dense classifier and sigmoid produce the good-quality probability; the evaluation threshold is 0.5.

The [saved evaluation results](quality-model-results.json) report test accuracy **95.25%**, good-class precision **97.75%**, recall **96.51%**, F1 **0.9712**, and ROC AUC **0.9894**. Of 64 bad segments, 57 were rejected and 7 accepted; of 315 good segments, 304 were accepted and 11 rejected.

The split policy is **mixed per recording**: different windows of a recording can appear in training, validation, and test sets. These internal results therefore measure performance on held-out segments, not independent participants or a prospective phone study. The class balance also makes accuracy alone insufficient; the confusion counts above expose false acceptances and rejections.

The bundled backend checkpoint is byte-identical to the evaluated training checkpoint (SHA-256 recorded in the results file). Evaluation metadata is included without local machine paths; source datasets and participant recordings are not redistributed here.
