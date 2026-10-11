# Windows port experiment

This branch explores whether omdrop's radio-backend contract can be implemented cleanly on Windows without changing the existing Linux backend.

## Goal

Prove the smallest useful path from Windows hardware to an AWDL-capable radio backend, while keeping AirDrop protocol logic above the radio layer unchanged.

The first milestone is **discovery, not file transfer**:

> A Windows machine can identify its Wi-Fi hardware and driver capabilities well enough to choose a viable AWDL strategy and explain blockers precisely.

No claim of Windows AirDrop support is made until it has been demonstrated on real hardware.

## Design rules

- Keep `main` suitable for upstream sync; Windows work stays isolated until it earns promotion.
- Preserve the existing radio-backend boundary instead of forking AirDrop protocol logic.
- Probe before changing machine state.
- Do not install drivers, disconnect Wi-Fi, enable monitor mode, or alter adapter configuration during capability probing.
- Prefer structured output that can later feed a GUI or backend selector.
- Separate observed facts from inferred capabilities and untested hypotheses.
- Every hardware-specific workaround needs a reproducible test and a documented reason.

## Capability stages

| Stage | Meaning | Evidence required |
| --- | --- | --- |
| `inventory` | Adapter and driver identified | Windows API / PowerShell inventory |
| `candidate` | Hardware is plausibly usable | Known chipset/driver plus documented radio capabilities |
| `raw80211` | Required frame access exists | Reproducible capture/injection test |
| `awdl-link` | AWDL peer traffic works | Packet trace and peer discovery |
| `airdrop` | End-to-end transfer works | Send and receive against an Apple device |

A later stage must never be reported merely because an earlier one succeeded.

## First implementation

`tools/windows/probe.ps1` is intentionally read-only. It collects:

- Windows version
- physical Wi-Fi adapters
- interface state
- adapter description and PnP identity
- installed driver provider/version/date when available
- native `netsh wlan show drivers` capabilities

It emits JSON by default so results are easy to compare between machines.

## Next experiments

Once probe output from real machines is available:

1. Map the detected chipset and Windows driver to known Linux/OWL results without assuming equivalent driver behavior.
2. Evaluate Windows WLAN/NDIS access paths for passive 802.11 observation.
3. Build a disposable raw-frame test only if the OS/driver path justifies it.
4. Attempt AWDL discovery before touching the AirDrop sender/receiver layer.

## Non-goals

This branch is not a Windows GUI, an installer, a replacement AirDrop implementation, or a promise that arbitrary Windows Wi-Fi hardware will work.
