# Dockerfile for building Ollama with ROCm and GTT support
# ready to serve home assistant
# Source: https://github.com/ollama/ollama
# Source: https://github.com/Maciej-Mogilany/ollama / https://github.com/rjmalagon/ollama-linux-amd-apu

FROM CI_REGISTRY/git/rocm-base:latest

# Set GPU specific env vars, preset RDNA 3.5 gfx1150 / gfx1151
# adjust as needed, list of GPUs supported by rocblas: https://github.com/ROCm/rocBLAS/blob/develop/library/src/handle.cpp#L81
ENV HCC_AMDGPU_TARGETS="$AMDGPU_TARGETS"
ENV HIP_ARCHS="$AMDGPU_TARGETS"

# Install deps
RUN apt-get -qq update && \
    apt-get install -qqy --no-install-recommends \
    golang \
    cmake && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN git config --global user.email "gitlab@gitlab.local" && \
	git config --global user.name "gitlab bot"

# Set WORKDIR
ENV WDIR=/build
WORKDIR $WDIR/
COPY src/*.patch $WDIR/

# Install Ollama
RUN git clone https://github.com/rjmalagon/ollama-linux-amd-apu ollama && cd ollama && \
	git apply $WDIR/ollama.patch && \
	cmake --preset 'ROCm 6' -DAMDGPU_TARGETS=$AMDGPU_TARGETS && \
	cmake --build --parallel --preset 'ROCm 6' && \
	cmake --install build --component HIP --strip && \
	( go run . list || true )

# Set ENV
ENV OLLAMA_FLASH_ATTENTION=1
ENV OLLAMA_KV_CACHE_TYPE=q8_0
ENV OLLAMA_HOST=0.0.0.0:11434
ENV OLLAMA_MODELS=/opt/llm-dl/
ENV ANONYMIZED_TELEMETRY=False
ENV DO_NOT_TRACK=True
ENV SCARF_NO_ANALYTICS=True

# Set VOLUME
VOLUME $OLLAMA_MODELS

# Set ENTRYPOINT
ENTRYPOINT ["sh", "-c", "cd /$WDIR/ollama; go run . serve"]

## Build using:
# docker build -t piper-rocm .

## Start using:
#docker run -d --restart on-failure \
# -v /opt/llm-dl:/opt/llm-dl \
# --network=host \
# --device=/dev/kfd \
# --device=/dev/dri \
# --group-add=video \
# --group-add=render \
# --ipc=host \
# --security-opt seccomp=unconfined \
# piper-rocm
