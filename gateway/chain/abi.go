package chain

import (
	_ "embed"
)

//go:embed abi_assets/FunctionsClient.json
var functionClientABI string

//go:embed abi_assets/FunctionsOracle.json
var functionOracleABI string
