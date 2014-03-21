package helpers

import (
	"net/http"
	"io/ioutil"
	"encoding/json"
	"fmt"
)

func ConstructServiceInstanceUrl(credentials map[string]interface{}) string {
	url := credentials["url"].(string)
	login := credentials["login"].(string)
	secret := credentials["secret"].(string)

	return fmt.Sprintf("http://%s:%s@%s", login, secret, url)
}

func FetchVcapServices(appUrl string) map[string]interface{} {
	resp, _ := http.Get(appUrl)

	respBody, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		panic(err)
	}

	var env map[string]interface{}
	if err := json.Unmarshal(respBody, &env); err != nil {
		panic(err)
	}

	var vcap_services map[string]interface{}
	if err := json.Unmarshal([]byte(env["VCAP_SERVICES"].(string)), &vcap_services); err != nil {
		panic(err)
	}
	return vcap_services
}

func FetchServicesInfo(appUrl, serviceName string) map[string]interface{} {
	vcap_services := FetchVcapServices(appUrl)
	services_info := vcap_services[serviceName].([]interface{})[0].(map[string]interface{})
	return services_info
}
