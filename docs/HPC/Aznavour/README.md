# Step-by-Step Guide: Install and Run Nextflow on SDSC Expanse

This guide walks you through installing Nextflow, preparing a container image, and running a pipeline on SDSC Expanse.

## Prerequisites
- Access to the **Aznavour Supercomputer at the Institute for Informatics and Automation Problems of the National Academy of Sciences of Armenia** system
- A valid **Aznavour Supercomputer account**
- Basic familiarity with **Linux commands**, **SLURM**, **git**
- **Tmux** for managing interactive sessions (optional but recommended)

## 1. Install Nextflow on Expanse

#### Step 1: Load Required Modules
Purge existing modules and load the required ones:
```bash
module purge
module load apptainer
module load java
```

### Step 2: Download and Install Nextflow

```bash
cd ~
curl -s https://get.nextflow.io | bash
export NEXTFLOW=$(pwd)/nextflow
export PATH=$NEXTFLOW:$PATH
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

Set up your email,so nextflow will send a notification:
```bash

export YOUREMAIL="YOUR_EMAIL_FOR_NOTIFICATION"
```


### Step 2: Load Required Modules Again

```
module purge
module load apptainer
module load java
```

### Step 3: Clone the Pipeline Repository

```
cd ~
git clone https://github.com/hovo1990/nf-core-hpcdockbench.git
```




### 3.1 Export nf-core-hpcdockbench to environment path


```bash
export HPCDOCKBENCH=~/nf-core-hpcdockbench
export PATH=$HPCDOCKBENCH:$PATH
```



## 4. Run the Pipeline in Batch Mode

To submit the job in batch mode instead of interactive mode:

```bash
sbatch aznavour.sb
```