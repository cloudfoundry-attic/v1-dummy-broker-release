package tests

import (
	"fmt"
	. "github.com/cloudfoundry-incubator/v1-dummy-broker-release/acceptance_tests/helpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/pivotal-cf-experimental/cf-test-helpers/cf"
	. "github.com/vito/cmdtest/matchers"
	"math/rand"
	"time"
)

var _ = Describe("Service Lifecycle", func() {
	BeforeEach(func() {
		LoginAsUser()
		rand.Seed(time.Now().UTC().UnixNano())
	})

	It("create service instance successfully", func() {
		serviceInstanceName := fmt.Sprintf("test-service-%d", rand.Intn(999999))
		Expect(Cf("services")).NotTo(Say(serviceInstanceName))
		//create service instance
		Expect(Cf("create-service", "v1-test", "free", serviceInstanceName)).To(ExitWithTimeout(0, 10*time.Second))
		//check that the service instance exists
		Expect(Cf("services")).To(Say(serviceInstanceName))
	})

	It("binds service instances to apps successfully", func() {
		serviceInstanceName := fmt.Sprintf("test-service-%d", rand.Intn(999999))
		appName := fmt.Sprintf("test-app-%d", rand.Intn(999999))
		Expect(Cf("services")).NotTo(Say(serviceInstanceName))
		Expect(Cf("apps")).NotTo(Say(appName))

		Expect(Cf("create-service", "v1-test", "free", serviceInstanceName)).To(ExitWithTimeout(0, 10*time.Second))
		Expect(Cf("push", appName, "-p", NewAssets().EnvApp)).To(Say("App started"))

		Expect(Cf("bind-service", appName, serviceInstanceName)).To(Say("OK"))
		Expect(Cf("restart", appName)).To(Say("App started"))

//		services_info := FetchServicesInfo("http://test-app-725953.10.244.0.34.xip.io	", "v1-test-n/a")
//
//		Expect(services_info["name"]).To(Equal(serviceInstanceName))
//
//		credentials := services_info["credentials"].(map[string]interface{})
//		instance_url := ConstructServiceInstanceUrl(credentials)


	})
})
