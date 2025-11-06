# Dockerfile for building Ollama with ROCm and GTT support
# ready to serve home assistant
# Source: https://github.com/ollama/ollama
# Source: https://github.com/Maciej-Mogilany/ollama / https://github.com/rjmalagon/ollama-linux-amd-apu

FROM CI_REGISTRY/git/rocm-base:latest

# Set working directory for build
ENV WDIR=/build
WORKDIR $WDIR/
COPY src/*.patch $WDIR/

# Install Ollama
ARG PARALLEL=8
RUN git clone --single-branch --depth=1 https://github.com/ollama/ollama ollama && cd ollama && \
	git apply $WDIR/ollama.patch && \
	cmake --preset 'ROCm 6' -DOLLAMA_RUNNER_DIR="rocm" && \
	cmake --build -j ${PARALLEL} --preset 'ROCm 6' && \
	cmake --install build --component HIP --strip && \
	go mod download && \
	GOFLAGS="'-ldflags=-w -s'" CGO_ENABLED=1 go build -trimpath -buildmode=pie -o /usr/bin/ollama . && \
	( ollama list || true )

# Set ENV
ENV OLLAMA_FLASH_ATTENTION=1
ENV OLLAMA_KV_CACHE_TYPE=q8_0
ENV OLLAMA_HOST=0.0.0.0:11434
ENV OLLAMA_MODELS=/opt/llm-dl/
ENV OLLAMA_MAX_LOADED_MODELS=1
ENV OLLAMA_NUM_PARALLEL=1
ENV OLLAMA_NEW_ENGINE=0
ENV ANONYMIZED_TELEMETRY=False
ENV DO_NOT_TRACK=True
ENV SCARF_NO_ANALYTICS=True

# Set VOLUME
VOLUME $OLLAMA_MODELS

# Set ENTRYPOINT
WORKDIR $WDIR/ollama
ENTRYPOINT ["ollama"]
CMD ["serve"]

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
