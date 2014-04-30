package helpers

import (
	"encoding/json"
	"os"
)

type IntegrationConfig struct {
	AppsDomain        string `json:"apps_domain"`
	SystemDomain      string `json:"system_domain"`
	ApiEndpoint       string `json:"api"`

	AdminUser         string `json:"admin_user"`
	AdminPassword     string `json:"admin_password"`

	SkipSSLValidation bool `json:"skip_ssl_validation"`

	ServiceAuthToken  string `json:"service_auth_token"`
}

func LoadConfig() (config IntegrationConfig) {
	path := os.Getenv("CONFIG")
	if path == "" {
		panic("Must set $CONFIG to point to an integration config .json file.")
	}

	return LoadPath(path)
}

func LoadPath(path string) (config IntegrationConfig) {
	config = IntegrationConfig{
		SkipSSLValidation: false,
		ServiceAuthToken: "36001246-f5d0-4d9a-aa33-7d2522fe1ea7",
	}

	configFile, err := os.Open(path)
	if err != nil {
		panic(err)
	}

	decoder := json.NewDecoder(configFile)
	err = decoder.Decode(&config)
	if err != nil {
		panic(err)
	}

	if config.ApiEndpoint == "" {
		panic("missing configuration 'api'")
	}

	if config.AdminUser == "" {
		panic("missing configuration 'admin_user'")
	}

	if config.ApiEndpoint == "" {
		panic("missing configuration 'admin_password'")
	}

	return
}
