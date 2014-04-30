package helpers

import (
	"net/http"
	"io/ioutil"
	"encoding/json"
	"fmt"
)

func GetInstanceUrl(appUrl string) string {
	services_info := fetchServicesInfo(appUrl, "v1-test-n/a")
	credentials := services_info["credentials"].(map[string]interface{})
	instance_url := constructServiceInstanceUrl(credentials)
	return instance_url
}

func constructServiceInstanceUrl(credentials map[string]interface{}) string {
	url := credentials["url"].(string)
	login := credentials["login"].(string)
	secret := credentials["secret"].(string)

	return fmt.Sprintf("http://%s:%s@%s", login, secret, url)
}

func fetchVcapServices(appUrl string) map[string]interface{} {
	resp, _ := http.Get(appUrl)
	defer resp.Body.Close()

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

func fetchServicesInfo(appUrl, serviceName string) map[string]interface{} {
	vcap_services := fetchVcapServices(appUrl)
	services_info := vcap_services[serviceName].([]interface{})[0].(map[string]interface{})
	return services_info
}
