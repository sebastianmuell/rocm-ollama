# Ollama ROCm

Ollama with ROCm support for accelerating inference on amd gpu.

## Build
docker build -t ollama-rocm .

## Usage
docker run -d --restart on-failure \
 -v /opt/llm-dl:/opt/llm-dl \
 --network=host \
 --device=/dev/kfd \
 --device=/dev/dri \
 --group-add=video \
 --group-add=render \
 --ipc=host \
 --security-opt seccomp=unconfined \
 ollama-rocm

## Contributing
Always welcome.

## Acknowledgment
ROCm Team - for maintaining rocm/dev-ubuntu-24.04 on docker hub

Ollama Team - for maintaining and developing ollama

Maciej-Mogilany - fork of Ollama with GTT memory support, see https://github.com/Maciej-Mogilany/ollama/tree/AMD_APU_GTT_memory

## License
GPLv3

## Project status
- Pinned to ollama branch v0.5.7 due to problems with newer versions, hopefully the GTT memory fix will be merged upstream soon.
- Not actively maintained.