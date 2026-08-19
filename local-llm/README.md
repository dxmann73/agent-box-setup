# Run local LLMs on a dedicated machine

Running LLM inference locally on the HX 370 / Radeon 890M laptop, benchmarking it, and driving a
local coding agent from it.

## Index


| Document                                            | Contains                                                         |
| --------------------------------------------------- | ---------------------------------------------------------------- |
| [Specification](../docs/specification/local-llm.md) | *What*: goal, target system, requirements, definition of done    |
| [Concepts and approach](concepts-and-approach.md)   | *Why*: intent, core concepts, approach, caveats, findings so far |
| [Implementation](implementation.md)                 | *How*: step index, execution order, rules while executing        |
| [From laptop to Kubernetes](kubernetes.md)          | Outlook: what changes as a multi-user service                    |




## Steps

Executable steps, referenced from [implementation.md](implementation.md):


| #   | Step                                                             |
| --- | ---------------------------------------------------------------- |
| 01  | [System prep and Vulkan verification](steps/01-system-prep.md)   |
| 02  | [Build llama.cpp with Vulkan](steps/02-build-llama-cpp.md)       |
| 03  | [Obtain models](steps/03-models.md)                              |
| 04  | [7B baseline: CPU, Vulkan, interactive](steps/04-bench-7b.md)    |
| 05  | [~30–32B dense benchmark](steps/05-bench-32b-dense.md)           |
| 06  | [Large MoE benchmark](steps/06-bench-large-moe.md)               |
| 07  | [GTT kernel tuning](steps/07-gtt-tuning.md)                      |
| 08  | [ROCm/HIP second backend](steps/08-rocm.md)                      |
| 09  | [Benchmark method, matrix and log](steps/09-benchmark-method.md) |
| 10  | [Ollama and the coding agent](steps/10-ollama-and-agent.md)      |




## Start here

New to this: [concepts-and-approach.md](concepts-and-approach.md) → [specification](../docs/specification/local-llm.md)
→ [implementation.md](implementation.md).

Executing it: [implementation.md](implementation.md), then follow the steps in order.