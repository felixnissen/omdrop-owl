# Windows capability probe

A deliberately small, read-only first step toward a Windows radio backend.

## Run

From PowerShell:

```powershell
.\tools\windows\probe.ps1 -Pretty
```

The probe writes JSON to stdout. Redirect it to a file when comparing machines:

```powershell
.\tools\windows\probe.ps1 -Pretty > windows-probe.json
```

## Safety

The probe does **not** change Wi-Fi state, adapter settings, drivers, routes, firewall rules, interfaces, or registry values. It only reads system/adapter information and runs the native `netsh wlan show` queries.

## Interpreting results

A successful run means only that the `inventory` stage is complete. It does not establish monitor-mode access, frame injection, AWDL compatibility, or AirDrop support.

See `docs/windows-port.md` for the staged evidence model and next experiments.
