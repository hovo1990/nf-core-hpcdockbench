# Create a GPU Instance in Jetstream2 (AlmaLinux 9)

## Prerequisites

- A Jetstream2 account with access to GPU instances.
- Familiarity with basic Linux commands and SSH.
- A `g3.large` instance (20GB VRAM) is recommended, though 12GB VRAM should be sufficient.

## Step 1: Launch a GPU Instance

1. Log in to the [Jetstream2 portal](https://use.jetstream-cloud.org/).
2. Select **Launch Instance**.
3. Choose **AlmaLinux 9** as the base image.
4. Select a GPU-enabled flavor (`g3.large` recommended).
5. Configure SSH access.
6. Start the instance and note the assigned public IP address.

## Step 2: Connect to the Instance

Use SSH to connect to the instance:

```bash
ssh your_username@your_instance_ip
```

## Step 3: Install Required Packages

### 3.1 Install Apptainer

```bash
sudo dnf install -y epel-release
sudo dnf install -y apptainer apptainer-suid libxslt-devel tmux
```

### 3.2 Install OpenJDK 21

```bash
sudo dnf install -y java-21-openjdk
```

### 3.3 Set Default Java Version

```bash
sudo alternatives --config java
```

Select the option corresponding to **OpenJDK 21**.

### 3.4 Reboot the Machine

```bash
sudo reboot -h now
```

After the reboot, reconnect using SSH:

```bash
ssh your_username@your_instance_ip
```

## Step 4: Install Nextflow

```bash
curl -s https://get.nextflow.io | bash
```

Verify installation:

```bash
nextflow -v
```

## Step 5: Test GPU Functionality with Apptainer

### 5.1 Pull the NVIDIA CUDA Image

```bash
mkdir -p ~/singularity_images
cd ~/singularity_images
apptainer pull docker://nvidia/cuda:12.0.1-runtime-ubuntu22.04
cd  ~
export SINGIMAGES=$(pwd)/singularity_images
```

### 5.2 Run `nvidia-smi` Inside the Apptainer Container

```bash
apptainer run --nv cuda_12.0.1-runtime-ubuntu22.04.sif nvidia-smi
```

If everything is set up correctly, this command should display GPU details.

## Step 6: Run the Pipeline

### 6.1 Start a `tmux` Session

```bash
tmux new-session -s hpcdockbench
```

### 6.2 Clone the hpcdockbench Repository

```bash
cd ~
git clone https://github.com/hovo1990/nf-core-hpcdockbench.git
```

### 6.2.1 Export nf-core-hpcdockbench to environment path and workflow


```bash
export HPCDOCKBENCH=$(pwd)/nf-core-hpcdockbench
export PATH=$HPCDOCKBENCH:$PATH

export NXF_SINGULARITY_CACHEDIR=$SINGIMAGES
export NXF_APPTAINER_CACHEDIR=$SINGIMAGES
export ICM_HOME=~/soft/icm/icms
export NFX_OPTS="-Xms=512m -Xmx=4g"
export NXF_GLIBC_VERSION=$(ldd --version | head -n1 | awk '{print $NF}')

nextflow run $HPCDOCKBENCH/main.nf \
   -resume \
   -profile singularity \
   --outdir ~/hpc_dock_bench_singularity \
   --icm_home $ICM_HOME
```




### 6.3 Manage the `tmux` Session

- To **detach** from the session: Press `Ctrl+B`, then `D`
- To **reconnect** to the session:

  ```bash
  tmux attach -t hpcdockbench
  ```

- To **kill the session**:

  ```bash
  tmux kill-session -t hpcdockbench
  ```

## Step 7: Check Output Files

The output files will be located in the `~/hpc_dock_bench_singularity` folder, as specified in the list of arguments.

## Conclusion

You have now successfully launched a GPU instance, installed necessary software, verified GPU functionality, and run a Nextflow pipeline on Jetstream2 using AlmaLinux 9. 🎉


