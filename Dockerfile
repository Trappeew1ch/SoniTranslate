# Use an NVIDIA CUDA base image compatible with torch+cu118
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV GRADIO_SERVER_NAME=0.0.0.0
ENV GRADIO_SERVER_PORT=7860
# Set environment variable for Coqui TTS license agreement
ENV COQUI_TOS_AGREED=1
# Set default device (can be overridden at runtime if needed)
ENV SONITR_DEVICE=cuda

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3-pip python3.10-venv git ffmpeg libsndfile1 build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -u 1000 user
USER user
ENV PATH="/home/user/.local/bin:${PATH}"

# Set working directory
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY --chown=user:user requirements_docker.txt ./

# Install Python dependencies
# Upgrade pip and install wheel first
RUN python3 -m pip install --upgrade pip wheel
# Install dependencies from the consolidated file
# Using --no-cache-dir to reduce image size
RUN python3 -m pip install --no-cache-dir -r requirements_docker.txt
# Install TTS separately as noted in requirements_xtts.txt
RUN python3 -m pip install --no-cache-dir TTS==0.21.1 --no-deps

# Copy the rest of the application code
COPY --chown=user:user . .

# Create necessary directories mentioned in app_rvc.py
RUN mkdir -p downloads logs weights clean_song_output _XTTS_ audio2/audio audio outputs

# Download UVR models during build (optional, makes startup faster)
# RUN python3 app_rvc.py --download-uvr-only # Need to add a CLI flag for this

# Expose the Gradio port
EXPOSE 7860

# Command to run the application
CMD ["python3", "app_rvc.py"]
