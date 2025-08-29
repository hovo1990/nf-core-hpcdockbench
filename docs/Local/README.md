# How to launch on local machine with an Ubuntu Linux

## Prerequisites


- Familiarity with basic Linux commands SSH.
- Apptainer installed
- Docker installed (requires separte license for ICM)


## Step 1: Install Java

```bash
sudo apt install openjdk-21-jdk
```


## Step 2: Select java

```bash
sudo update-alternatives --config java
```

Select the option corresponding to **OpenJDK 21**.


## Step 3: Install Required Packages

### 3.1 Install Docker

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

### 3.2: Install docker packages

```bash
 sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 3.3: Test if docker works

```bash
sudo docker run hello-world

```

### 3.4: To create the docker group and add your user:

```bash
 sudo groupadd docker
 sudo usermod -aG docker $USER
```

Log out and log back.

### 3.5: Verify that you can run docker commands without sudo.

```bash
docker run hello-world
```

### 3.6: Install Nvidia Container toolkit

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/liexport NXF_SINGULARITY_CACHEDIR="/home/$USER/singularity_images"
export NXF_APPTAINER_CACHEDIR="/home/$USER/singularity_images"
bash jtgpu.sb

### 3.7: Update the packages list

```bash
sudo apt-get update
```


### 3.8: Install the NVIDIA Container Toolkit packages:

```bash

### 3.4: To create the docker group and add your user:

```bash
 sudo groupadd docker
 sudo usermod -aG docker $USER
```


### 3.9: Configure docker

```bash
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```


### 3.10: Test if Nvidia GPU works inside docker

```bash
docker run --rm  --gpus all ubuntu nvidia-smi
```

if you get an output like this, this means everything is ok:


```
Tue Feb 25 05:51:20 2025
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 560.35.03              Driver Version: 560.35.03      CUDA Version: 12.6     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA TITAN Xp                Off |   00000000:0C:00.0 Off |                  N/A |
| 23%   31C    P8              9W /  250W |      20MiB /  12288MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
+-----------------------------------------------------------------------------------------+
```




### 3.11 Install Apptainer (Option 2)

```bash
sudo add-apt-repository -y ppa:apptainer/ppa
sudo apt update
sudo apt install -y apptainer

```


#### Step 3.11.1: Test GPU Functionality with Apptainer

##### 3.11.1.1 Pull the NVIDIA CUDA Image

```bash
mkdir -p ~/singularity_images
cd ~/singularity_images
apptainer pull docker://nvidia/cuda:12.0.1-runtime-ubuntu22.04
cd  ~
export SINGIMAGES=$(pwd)/singularity_images
```

### 3.11.1.2  Run `nvidia-smi` Inside the Apptainer Container

```bash
apptainer run --nv cuda_12.0.1-runtime-ubuntu22.04.sif nvidia-smi
```

If everything is set up correctly, this command should display GPU details.



### 3.4 Reboot the Machine

```bash
sudo reboot -h now
```



## Step 4: Install Nextflow

```bash
curl -s https://get.nextflow.io | bash
```

Verify installation:

```bash
nextflow -v
```



## Step 6: Run the Pipeline

### 6.1 Start a `tmux` Session

```bash
tmux new-session -s hpcdockbench
```

### 6.2 Clone the hpcdockbench Repository

```bash
cd ~
git clone  https://github.com/hovo1990/nf-core-hpcdockbench.git
```


### 6.3 Export nf-core-hpcdockbench to environment path


```bash
export HPCDOCKBENCH=$(pwd)/nf-core-hpcdockbench
export PATH=$HPCDOCKBENCH:$PATH
```





### 6.4 Run the Workflow using Docker

### 6.4.1 Setting up Java options

```bash
export NFX_OPTS="-Xms=512m -Xmx=4g"
```

1. export: Sets an environment variable available to processes started from this shell.
2. NFX_OPTS: A variable used by Nextflow to define Java options.
3. -Xms=512m: Sets the initial memory allocation for the Java Virtual Machine (JVM) to 512 megabytes.
4. -Xmx=4g: Sets the maximum memory allocation for the JVM to 4 gigabytes.


### 6.4.2 Run pipeline using Apptainer/Singularity

```bash
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
1. nextflow: Runs the Nextflow executable located in the home directory (~).
2. run: A command telling Nextflow to start a pipeline.
3. -profile apptainer: Specifies that the pipeline should run using Apptainer/Singularity containers. This ensures a consistent environment.
4. $HPCDOCKBENCH/main.nf: Path to the main Nextflow script.
6. -resume: Tells Nextflow to continue from where it left off if the pipeline was previously interrupted, avoiding restarting completed steps.



### 6.5 Run the Workflow using Docker (requires separate license for ICM-PRO)



```bash
export ICM_HOME=~/soft/icm/icms
export NFX_OPTS="-Xms=512m -Xmx=4g"
export NXF_GLIBC_VERSION=$(ldd --version | head -n1 | awk '{print $NF}')
nextflow  \
    run -profile docker \
    $hpcdockbench/main.nf  \
    -params-file config.yml  \
    --outdir ~/hpc_dock_bench \
    -resume
```




### 6.7  Manage the `tmux` Session

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

The output files will be located in the `~/hpc_dock_bench` folder.

## Conclusion

You have now successfully launched a GPU instance, installed necessary software, verified GPU functionality, and run a Nextflow pipeline on Ubuntu machine. 🎉


