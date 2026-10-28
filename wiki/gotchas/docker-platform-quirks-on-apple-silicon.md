---
type: Gotcha
title: Docker platform quirks on Apple Silicon
description: With OrbStack on an arm64 Mac, run --platform can fail to find a local amd64 image, and a registry tag can silently resolve to arm64.
tags: [docker, orbstack, build]
---

The build and test run x86-64 code on an arm64 host, which trips three things.

# Symptoms and fixes

* **`docker run --platform linux/amd64 <locally built image>` says the image does
  not exist.** The image was built `FROM --platform=linux/amd64` and is amd64
  only, so leave `--platform` off the `run` of locally built images.
* **`ubuntu:22.04` runs as arm64** if an arm64 variant is present locally, and
  x86 binaries then fail with "dynamic loader not found" or `ldd` saying "not a
  dynamic executable". For registry images, pass `--platform linux/amd64` on the
  `run`. This once looked like "the binary needs a newer glibc" and is not.
* **`docker run -i` is required** when the script arrives on stdin (a heredoc to
  `bash -s`), otherwise the container reads an empty script and prints nothing.

# Related

[Build pipeline](/architecture/build-pipeline.md), [build and test playbook](/playbooks/build-and-test.md).
