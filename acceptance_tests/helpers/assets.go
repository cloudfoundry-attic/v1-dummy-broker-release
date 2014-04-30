package helpers

type Assets struct {
	TestApp string
}

func NewAssets() Assets {
	return Assets{
		TestApp: "../assets/env-app",
	}
}
