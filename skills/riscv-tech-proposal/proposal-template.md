# RISC-V Tech Proposal Template

---

## Proposer

| Field | Value |
|-------|-------|
| Name | [Author Name(s)] |
| Organization/Affiliation | [Organization Name] |

## Introduction

[1-2 paragraphs summarizing the proposal. First paragraph: what is being proposed. Second paragraph: why it matters and expected impact.]

Example (from ACPI RBRT):
> We are proposing an architecture-specific ACPI table, the RISC-V Error Bank Table (RBRT), to provide a standardized discovery mechanism for RISC-V hardware error sources. The goal is to define an ACPI-based framework that bridges the gap between RISC-V error reporting capabilities and operating system support in Linux.
>
> By standardizing how the OS discovers error source locations, register bases, interrupt mappings, and related topology information, ACPI RBRT would enable Linux to manage hardware errors directly and support kernel-first error handling where appropriate.

## Motivation and Problem Statement

### [Sub-problem 1, e.g., Scalability Challenges]

[Describe the specific problem with concrete scenarios and data.]

Example:
> In modern server SoCs with high core counts (e.g. EPYC Turin, up to 192 cores), the single command queue protected by a spinlock creates a severe serialization bottleneck. When multiple CPUs simultaneously issue IOTLB invalidation commands, lock contention leads to:
> - Performance degradation proportional to core count
> - Increased latency for memory management operations
> - Poor scaling of I/O-intensive workloads

### [Sub-problem 2, e.g., Virtualization Overhead]

[Continue with additional problem dimensions...]

### Why Existing Extensions Are Insufficient

[Mandatory section. Analyze each existing RISC-V extension/mechanism and explain why it falls short.]

Example:
> The current RISC-V performance monitoring infrastructure focuses exclusively on per-hart (core) counters:
>
> **Zihpm**: Defines per-hart CSRs for counting core-local events. These counters are CSR-based and inherently tied to a single hart.
>
> **Sscofpmf**: Adds overflow interrupt support and privilege-mode filtering to per-hart counters, but still operates within the per-hart CSR paradigm.
>
> **SBI PMU**: Provides a firmware abstraction layer for per-hart counters. It does not define any interface for system-level components.
>
> None of these extensions address [the specific gap this proposal fills].

## Definitions

| Term | Definition |
|------|-----------|
| [TERM1] | [Full name and brief description] |
| [TERM2] | [Full name and brief description] |
| ... | ... |

Example:
| Term | Definition |
|------|-----------|
| RERI | The RAS Error-record Register Interface |
| KFM | Kernel-First Mode |
| FFM | Firmware-First Mode |
| ACPI | Advanced Configuration and Power Interface |

## Background

### [Topic 1, e.g., Current RISC-V Mechanism]

[Detail the existing RISC-V mechanisms relevant to the proposal.]

### [Topic 2, e.g., Solutions in Other Architectures]

[Describe how x86/ARM solve the same problem.]

Example:
> On x86 platforms, the Machine Check Architecture (MCA) provides a standardized framework for hardware error reporting. Error record registers are mapped to per-core system registers, and corrected errors are delivered through dedicated interrupts.
>
> On Arm platforms, error record register sets are distributed across individual components. Arm addresses the discovery gap with the ACPI AEST (Arm Error Source Table), which provides a standardized discovery mechanism.

### [Topic 3, e.g., Linux Kernel Context]

[Describe the relevant Linux kernel subsystem and its current state on RISC-V.]

## Proposed Solution

[This is the core technical content of the proposal. Structure varies by proposal type.]

### [Sub-section 1, e.g., Architecture Overview]

[High-level description of the proposed solution.]

### [Sub-section 2, e.g., Register Interface / Protocol Definition]

[Detailed technical specification.]

### [Sub-section 3, e.g., Software Interface / Linux Integration]

[How the solution integrates with existing software stack.]

### [Sub-section 4, e.g., Compatibility and Migration]

[How the solution maintains backward compatibility.]

## Objectives

The objective of this work is to [high-level goal].

The proposed work aims to enable software to:
- [Objective 1, using verb: Define, Implement, Enable, Provide, etc.]
- [Objective 2]
- [Objective 3]
- ...

Example:
> The objective of this work (ACPI RBRT) is to define a standardized ACPI-based mechanism for discovering RISC-V hardware error sources, so that operating systems can support consistent RAS handling across implementations.
>
> The proposed work aims to enable software to:
> - discover hardware error sources in a uniform way
> - associate them with the relevant platform resources
> - determine how error events are reported and notified
> - apply appropriate error handling policies

## Exclusions (Optional)

[What is explicitly NOT in scope. Write "None" if not applicable.]

## Collaborations

- [SIG/TG Name 1]
- [SIG/TG Name 2]

Common SIGs/TGs:
- Datacenter SIG
- Platform Runtime Services TG
- Linux SIG
- Hypervisor SIG
- Privileged Software TG

## Sponsoring Organizations

These Premier and Strategic Members support this Proposal:
1. [Organization 1]
2. [Organization 2]

## Milestones

| Milestone | Description |
|-----------|-------------|
| M1: Task Group Formation | [Description] |
| M2: Specification Draft v0.1 | [Description] |
| M3: Community Review v0.5 | [Description] |
| M4: QEMU + Linux PoC | [Description] |
| M5: Specification Draft v0.9 | [Description] |
| M6: Hardware Prototype | [Description] |
| M7: Ratification Review v1.0 | [Description] |

## References

[1] [Title: URL or Document ID]
[2] [Title: URL or Document ID]
...
