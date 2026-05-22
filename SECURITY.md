# Security

Do not open public issues containing credentials, private inventories, customer
logs, or exploit details against live systems.

Plugin safety expectations:

- Invalid manifests disable only that plugin.
- Unknown permissions disable only that plugin.
- Plugins should not execute code inside ATL Terminal.
- Destructive command groups must require explicit confirmation.
