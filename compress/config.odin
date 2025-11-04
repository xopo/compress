package main

import "core:encoding/json"
import "core:fmt"

Config :: struct {
	captureStore: string `json:"store"`,
	encoder:      string `json:"encoder"`,
}

// embed cofig file at build time
data :: #load("../config.json")

get_config :: proc() -> Config {
	conf: Config
	if json_err := json.unmarshal(data, &conf); json_err != nil {
		fmt.eprintf("problem deconding, or missing config file: %q\n", json_err)
	}
	return conf
}
