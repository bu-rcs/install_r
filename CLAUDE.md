# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

System-administration scripts for installing R from source and migrating R packages
on a shared HPC cluster (Boston University SCC). There is no build system, test suite,
or application — these are operational scripts run by hand on the cluster, in sequence,
by an admin with write access to `/share/pkg.8`. They depend on the cluster's
environment-module system (`module load ...`) and a fixed directory layout under
`/share/pkg.8/r/$VERSION/` (`DIST`, `src`, `build`, `install`).

## The two workflows

**1. Build a new R version from source — [install_R.sh](install_R.sh)**
Run from inside a version directory (e.g. `/share/pkg.8/r/4.2.3`) after exporting
`VERSION`, e.g. `export VERSION=4.2.3`. It downloads the CRAN tarball into `DIST/`,
configures (with `flexiblas` for swappable BLAS/LAPACK), builds, `make install`s,
copies GCC runtime shared libs (`libgfortran`, `libstdc++`, `libgcc_s`) into the R
`lib` so R starts without the gcc module loaded, rewrites `etc/ldpaths` to point at
`/usr/java/default` (so a Java update doesn't break rJava), and finally runs
[install_bioconductor.R](install_bioconductor.R) to install BiocManager + tidyverse.
Toolchain is pinned: `gcc/12.2.0`, `texlive/2022`, `flexiblas/3.3.1`.

**2. Migrate packages from an old R version to a new one — [install_packages.sh](install_packages.sh)**
`./install_packages.sh <old_version> <new_version>`. Loads `R/<old>`, dumps the
installed package names to `installed_r_packages.txt` via
[list_packages.R](list_packages.R), then `module purge`s, loads `R/<new>` +
`gcc/12.2.0` + `cmake/3.22.2`, and reinstalls that list with
[install_packages.R](install_packages.R) (logs per-package SUCCESS/FAILED to
`package_installation_log.txt`).

## Things that aren't obvious from reading one file

- The two `install_packages.*` scripts reference their `.R` counterparts by the
  **deployed** absolute path `/share/pkg.8/r/...`, not the repo copy. Editing a script
  here has no effect until it is copied to that location on the cluster.
- `install_R.sh` is run via `bash`/`sh` but `install_packages.sh` needs a **login
  shell** (`#!/bin/bash -l`) because `module` is only defined in login shells.
- [install_packages.R](install_packages.R) force-reinstalls `Matrix` unconditionally —
  a deliberate workaround (Nov 2025) for a bad Matrix build shadowing the CRAN one.
  Don't "clean up" that line.
- Hard-coded versions (`gcc/12.2.0`, `flexiblas/3.3.1`, `cmake/3.22.2`, the
  `pkg.7`→`pkg.8`/alma8 paths, `R-4/` URL path) are environment facts, not defaults to
  generalize. Changing them is a real migration decision.
- The header comments in [install_R.sh](install_R.sh) record the change history
  (pkg.7→pkg.8, flexiblas added) — keep updating them when modifying the build.
