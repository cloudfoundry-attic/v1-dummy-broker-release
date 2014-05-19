package helpers

type Assets struct {
	TestApp 		string
	V2ServiceBroker string
}

func NewAssets() Assets {
	return Assets{
		TestApp: "../assets/env-app",
		V2ServiceBroker: "../assets/v2_broker",
	}
}
