# Step-by-Step Guide: Install and Run Nextflow on SDSC Expanse

This guide walks you through installing Nextflow, preparing a container image, and running a pipeline on SDSC Expanse.

## Prerequisites
- Access to the **SDSC Expanse** system
- A valid **Expanse project account**
- Basic familiarity with **Linux commands**, **SLURM**, **git**
- **Tmux** for managing interactive sessions (optional but recommended)

## 1. Install Nextflow on Expanse

#### Step 1: Load Required Modules
Purge existing modules and load the required ones:
```bash
module purge
module load slurm
module load gpu/0.17.3b
module load gcc/10.2.0/i62tgso
module load openjdk/11.0.12_7/xkfgsx7
module load singularitypro/3.11
```

### Step 2: Download and Install Nextflow

```bash
cd ~
curl -s https://get.nextflow.io | bash
export NEXTFLOW=$(pwd)/nextflow
export PATH=$NEXTFLOW:$PATH
```


## 2. Prepare a Singularity Container Image

### Step 1: Define Your Project Variables

Set up your project name and username:
```bash
EXPANSEPROJECT='YOUR_PROJECT_NAME_ON_EXPANSE'
USERNAME=$USER
```


## 3. Run the Nextflow Pipeline


### Step 1: Start a Tmux Session

To avoid losing progress in case of connection issues, create a tmux session:


```
tmux new-session -s hpcdockbench
```


To reconnect later:
```
tmux attach -t hpcdockbench
```

To terminate the session:
```
tmux kill-session -t hpcdockbench
```

Set up your project name, username and email,so nextflow will send a notification:
```bash
export EXPANSEPROJECT='YOUR_PROJECT_NAME_ON_EXPANSE'
export USERNAME=$USER
export YOUREMAIL="YOUR_EMAIL_FOR_NOTIFICATION"
```


### Step 2: Load Required Modules Again

```
module purge
module load slurm
module load gpu/0.17.3b
module load gcc/10.2.0/i62tgso
module load openjdk/11.0.12_7/xkfgsx7
module load singularitypro/3.11
```

### Step 3: Clone the Pipeline Repository

```
cd /expanse/lustre/projects/$EXPANSEPROJECT/$USERNAME
git clone https://github.com/hovo1990/nf-core-hpcdockbench.git
```




### 3.1 Export nf-core-hpcdockbench to environment path


```bash
export MAINPATH=/expanse/lustre/projects/$EXPANSEPROJECT/$USERNAME/
export SINGIMAGES=$MAINPATH/singularity_images
export hpcdockbench=$MAINPATH/nf-core-hpcdockbench
export PATH=$hpcdockbench:$PATH
```




### modify batch script

```
sed -i "s|<<SINGIMAGES>>|${SINGIMAGES}|g" config.yml
```

### Step 5: Run the Workflow
```bash
bash expanse.sb
```

## 4. Run the Pipeline in Batch Mode

To submit the job in batch mode instead of interactive mode:

```bash
sbatch expanse.sb
```