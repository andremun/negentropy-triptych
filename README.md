# Negentropy Triptych

This repository holds the MATLAB code behind the artwork *Negentropy
Triptych* (Kate Smith-Miles & Mario Andrés Muñoz-Acosta, 2019). It also
holds the code for the experiments in Smith-Miles and Muñoz (2022) [1].

The code arranges 306 tile images into an 18x17 mosaic. It searches for
arrangements at the extremes of a visual order-disorder spectrum.

Each tile is a contour plot of a continuous black-box optimization test
function. Muñoz and Smith-Miles (2020) [2] generated these functions with
a space-filling instance-generation method. This method was part of the
ARC-funded project "Stress-testing algorithms: generating new test
instances to elicit insights". Figshare hosts the 306 tile images [3].

These images also appear in the University of Melbourne's Algorithms of
Art gift range:
https://www.unimelb.edu.au/shop/melbourne-story/aoa-gift-range

## Learn more

- Podcast: "The algorithms of art", University of Melbourne Pursuit.
  https://pursuit.unimelb.edu.au/podcasts/the-algorithms-of-art
- Public lecture: "When mathematics becomes art - the unexpected beauty
  of self-evolving mathematical functions".
  https://www.youtube.com/watch?v=n4pw8FmEZ40

## Background

Each test function landscape, rendered as a 2D contour plot, shows a
light-colored ridge (a "blue river") against a darker background. The
code treats the 306 landscape images as tiles. It searches for a mosaic
layout that maximizes or minimizes a visual measure of order, such as:

- The mutual information between tile position and pixel intensity.
- The joint entropy between neighboring tiles, computed two ways:
  - "local": the fraction of shared foreground pixels over the whole
    tile.
  - "edge": the fraction of shared foreground pixels along the touching
    edge only.
- The size of the largest connected foreground region across the mosaic.
- How well each 2x2 block of tiles matches one of a set of chosen
  arrangements of the 26 primitives (canonical binary shapes).

The search is a local search. It starts from a layout, and repeatedly
proposes one of seven moves. It keeps the move only when the move
improves the chosen cost function. The seven moves are:

- Swap two random tiles.
- Swap a tile with its left, right, top, or bottom neighbor.
- Flip a row left-right.
- Flip a column up-down.

## Project structure

```
negentropy-triptych/
├── autoart.m                    Local search that optimizes one mosaic layout
├── randart.m                     Evaluates the cost function on random layouts
├── artworkfcn.m                   Shared helper functions (see below)
├── downloadRawImages.m             Fetches the 306 tile PNGs from figshare
├── kdpee.m                         Third-party k-d partitioning entropy estimator
├── kdpeemex.mexw64                 Compiled MEX binary kdpee.m calls (Windows)
├── kdpeemex.mexa64                 Compiled MEX binary kdpee.m calls (Linux)
├── kdpee/                          Vendored kdpee C source, for other platforms
├── collectResultsPaper.m       Post-processing script that builds the paper figures
├── trial_autoart.m             SLURM array-job wrapper around autoart.m
├── trial_rnd_mosaic.m          SLURM array-job wrapper for random-mosaic evaluation
├── test_random_mosaics_clust.m   Cost function type 4 evaluator trial_rnd_mosaic.m calls
├── launch_autoart.sh            SLURM sbatch script that runs trial_autoart.m
├── launch_job_exec.sh            SLURM sbatch script that runs trial_rnd_mosaic.m
├── launch_randart.sh            Historical sbatch script naming a missing trial_randart.m
├── autoart_1e6_cost/              Inputs for the 1e6-layout random-mosaic experiment
│   └── result_gen_rand_mosaics_E0.mat   Precomputed baseline trial_rnd_mosaic.m reads
└── data/
    ├── poster_idx.mat             Starting layouts used for the printed poster
    ├── raw_image_data.mat         Cached tile images, binary masks, and primitive data
    ├── result_triptych.mat        Layouts and cost values for the published triptych
    └── raw_images/                306 raw tile PNGs (not committed, see Data below)
```

`artworkfcn.m` is not called directly. It defines the functions the other
scripts use, and injects them into the caller workspace with `assignin`.
`autoart.m`, `randart.m`, and `collectResultsPaper.m` each call
`artworkfcn;` first, before they use any of these functions:

| Function | Purpose |
|---|---|
| `genRawData` | Reads the 306 raw tile PNGs and builds the primitives and pattern tables |
| `getfromfile` | Loads one named variable from a `.mat` file |
| `costGLOBAL` | Cost function dispatcher for the six order/disorder measures |
| `costEDGE`, `costLOCAL` | Joint-entropy cost between two tiles |
| `rendercolor`, `renderindexed`, `renderbinary` | Render a layout as a color, indexed, or binary mosaic image |
| `mutationrndswap`, `mutationlswap`, `mutationrswap`, `mutationtswap`, `mutationbswap`, `mutationfliplr`, `mutationflipud` | The seven local search moves |

## Requirements

- MATLAB with the Image Processing Toolbox (`rgb2ind`, `regionprops`,
  `bwareafilt`) and the Statistics and Machine Learning Toolbox (`nanmean`).
- A compiled MEX binary for the k-d partitioning entropy estimator [4].
  This repository ships `kdpeemex.mexw64` (Windows) and `kdpeemex.mexa64`
  (Linux). MATLAB picks the one that matches your platform automatically.
  Cost function types 1 and 2 (see Usage) call it through `kdpee.m`. The
  other cost function types do not need it. On macOS or another Linux
  architecture, build your own MEX file. Run `kdpee/mat_oct/mexme.m`
  from inside `kdpee/mat_oct/`. Copy the resulting `kdpeemex.mex*` file
  next to `kdpee.m`.
- A SLURM cluster, only for `trial_autoart.m` and `trial_rnd_mosaic.m`
  (or their `launch_autoart.sh` and `launch_job_exec.sh` sbatch
  wrappers), which read the `SLURM_ARRAY_TASK_ID` environment variable.
- Internet access, only the first time `data/raw_image_data.mat` needs to
  be rebuilt, so `downloadRawImages.m` can reach the figshare API. Needs
  no extra toolbox (`webread`/`websave` are base MATLAB).

## Data

`data/raw_image_data.mat` holds the data that `autoart.m` and `randart.m`
load at start-up:

- The 306 tile images, in three formats: true-color, indexed, and binary
  foreground/background.
- The 26 binary primitive shapes.
- The probability that each tile matches a primitive.
- The table of 2x2 primitive patterns cost function type 6 uses.

If `data/raw_image_data.mat` is missing, `autoart.m` rebuilds it from the
306 raw tile PNGs in `data/raw_images/`. If that folder is missing or
empty, `autoart.m` calls `downloadRawImages.m` first. That script fetches
the 306 images from the figshare dataset [3] through the public figshare
API, and saves them there.

Call `downloadRawImages` directly to pre-populate `data/raw_images/`
ahead of time. Or download the images by hand from
https://doi.org/10.6084/m9.figshare.13082474 and place them in
`data/raw_images/`.

This repository already ships `data/raw_image_data.mat`, so a normal run
of `autoart.m` never takes this path. This path only runs if you delete
that cache, or rebuild it from a newer image set.

A sandboxed environment blocks outbound requests to figshare, so
`downloadRawImages.m` has not run yet. Test it on a machine with normal
internet access before you rely on it.

`data/poster_idx.mat` holds the layout used as the starting point for the
printed poster. `data/result_triptych.mat` holds the layouts and cost
values for the left, center, and right panels of the published
*Negentropy Triptych*.

## Usage

Create the output folders before you run `autoart.m`, since `autoart.m`
does not create them:

```matlab
mkdir data/images
mkdir data/autoresults
```

Run a local search:

```matlab
autoart(nseed, ftype, minmax, nswaps)
```

- `nseed`: integer from 1 to 100, selects one of 100 fixed random seeds.
- `ftype`: cost function type, 1 to 6 (see the table below).
- `minmax`: `true` to maximize the cost function (search for order),
  `false` to minimize it (search for disorder).
- `nswaps`: number of local search iterations.

| `ftype` | Cost function |
|---|---|
| 1 | Mutual information between tile position and pixel intensity |
| 2 | Mutual information between tile position and the Laplacian of pixel intensity |
| 3 | Mean joint entropy between each tile and its neighbors, from shared foreground pixels |
| 4 | Mean joint entropy between each tile and its neighbors, along the touching edge only |
| 5 | Size of the largest connected foreground region |
| 6 | Mean best match between each 2x2 block of tiles and the primitive pattern table |

`autoart.m` saves the final mosaic image to `data/images/`. It saves the
layout, cost trace, mutation-operator usage counts, and total run time
(`ttcomp`) to `data/autoresults/`.

Evaluate cost function type 6 on random layouts:

```matlab
randart(datadir, idx, J)
```

- `datadir`: folder holding a copy of `raw_image_data.mat`. For a
  direct call against this repository's own data, use `'./data/'`.
- `idx`: matrix of layouts, one per column.
- `J`: matrix of cost values to fill in. `randart` skips any entry that
  is not `NaN`.

`collectResultsPaper.m` is not a function. It is a script you run cell by
cell. It loads the results from the local search runs and the random
baseline, and produces the figures for [1]: two example test-function
landscapes, the triptych, all 24 primitive-pattern illustrations, the
extreme-cost mosaics, the cost distribution histograms, and the
convergence curves.

If `data/result_randart.mat` is missing, `collectResultsPaper.m`
rebuilds it by calling `randart` on 1e6 random layouts. That path needs
a copy of `data/raw_image_data.mat` at
`data/rndresults/raw_image_data.mat`. `data/result_randart.mat` already
exists on the repository owner's machine, so a normal run for them never
takes this path.

### Running on a SLURM cluster

Submit the local search array job with `sbatch launch_autoart.sh`. It
runs `trial_autoart.m` (see Reproducibility below).

Submit the random-mosaic baseline array job with `sbatch
launch_job_exec.sh`. It runs `trial_rnd_mosaic.m`, which in turn calls
`test_random_mosaics_clust.m`. Both expect two files in
`autoart_1e6_cost/` that this repository does not ship:

- `img_idx_1e6.mat`, a 435 MB matrix of 1e6 random layouts. It exists on
  the repository owner's machine but is too large for a normal git
  commit. GitHub rejects any single file over 100 MB.
- `imagedata.mat`, holding the same binary tile masks as
  `data/raw_image_data.mat` in this repository, under the historical
  flat filename this function expects. Copy or rename a copy of
  `data/raw_image_data.mat` to `autoart_1e6_cost/imagedata.mat` to
  supply it.

`result_gen_rand_mosaics_E0.mat`, the third file `trial_rnd_mosaic.m`
reads, is small enough that this repository does ship it, already in
`autoart_1e6_cost/`.

This repository also has `launch_randart.sh`, an older sbatch script
that names a script called `trial_randart.m`, not present anywhere this
project's history has been checked. `launch_job_exec.sh` is the
confirmed, current launcher for `trial_rnd_mosaic.m`. Treat
`launch_randart.sh` as historical.

All three sbatch scripts assume a folder layout from the original
cluster run. Edit the paths inside them before you submit any job.
Change `cd ~/MATLAB/autoart` in the `.sh` files. Change the `data/...`
paths inside the `.m` files to match your own setup.

## Reproducibility

`autoart.m` fixes the random seed with `rng('default')`, draws 100 seed
values with `randi(100,100,1)`, and then reseeds with `rng(rseeds(nseed))`
before the search starts. The same `nseed` always produces the same
sequence of local search moves.

`trial_autoart.m` used to set `minmax = iid(tid,2)==1`. Column 2 of `iid`
holds the cost function type (2, 5, or 6). This made `minmax` always
false, so every array job minimized its cost function and never
maximized it. It now reads `minmax = iid(tid,3)==1`. Column 3 varies the
search direction, so the 60-job array covers all 10 seeds, 3 cost
function types, and 2 search directions, as intended. No
`data/autoresults/` files exist in this repository yet, so this change
does not invalidate any committed result.

## References

[1] Smith-Miles, K., & Muñoz, M. A. (2022). Optimal construction of
montages from mathematical functions on a spectrum of order-disorder
preference. *Journal of Mathematics and the Arts*, 16(4), 347-373.
https://doi.org/10.1080/17513472.2022.2139663

[2] Muñoz, M. A., & Smith-Miles, K. (2020). Generating new space-filling
test instances for continuous black-box optimization. *Evolutionary
Computation*, 28(3), 379-404. https://doi.org/10.1162/evco_a_00262

[3] Muñoz Acosta, M. A. (2026). Individual images without axes. figshare.
Figure. https://doi.org/10.6084/m9.figshare.13082474

[4] Stowell, D., & Plumbley, M. D. (2009). Fast multidimensional entropy
estimation by k-d partitioning. *IEEE Signal Processing Letters*, 16(6),
537-540. Implementation: https://github.com/danstowell/kdpee. Released
under the GNU General Public License. See the header of `kdpee.m` for the
license text and terms.
