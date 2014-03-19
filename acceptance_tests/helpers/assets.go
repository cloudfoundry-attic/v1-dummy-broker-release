package helpers

type Assets struct {
	EnvApp string
}

func NewAssets() Assets {
	return Assets{
		EnvApp: "../assets/env-app",
	}
}
