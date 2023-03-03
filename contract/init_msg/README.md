this folder will determine init msg for smart contracts

every init msg json file should look like this

```json
{
    "wasm":"cw20_ics20",
    "init": {
        "allowlist": [
            {
                "contract": ""
            }
        ],
        "default_timeout": 300,
        "gov_contract": ""
    }
}
```

deployment script will go over all available init_msg in a network and instantiate smart contracts. Make sure that wasm actually refers to a wasm file that exists in corresponding wasm/network