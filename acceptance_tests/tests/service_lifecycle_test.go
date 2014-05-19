package tests

import (
	. "github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	. "github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
	"net/http"

	"github.com/cloudfoundry-incubator/v1-dummy-broker-release/acceptance_tests/helpers"
)

var _ = Describe("Service Lifecycle", func() {

	defaultTimeout := 60
	var appName string

	BeforeEach(func() {
		appName = RandomName()

		Eventually(Cf("push", appName, "-m", "256M", "-p", helpers.NewAssets().TestApp, "-no-start"), defaultTimeout).Should(Exit(0))
	})

	AfterEach(func() {
		Eventually(Cf("delete", appName, "-f"), defaultTimeout).Should(Exit(0))
	})

	It("Allows users to create, bind, write to, read from, unbind, and destroy the service instance", func() {
		serviceInstanceName := RandomName()

		Eventually(Cf("create-service", environment.ServiceInfo.ServiceName, environment.ServiceInfo.PlanName, serviceInstanceName), defaultTimeout).Should(Exit(0))
		Eventually(Cf("bind-service", appName, serviceInstanceName), defaultTimeout).Should(Exit(0))

		fiveMinutes := 5 * 60
		Eventually(Cf("start", appName), fiveMinutes).Should(Exit(0))

		instance_url := helpers.GetInstanceUrl(AppUri(appName))

		resp, _ := http.Get(instance_url)
		Expect(resp.StatusCode).To(Equal(200), "unable to use the credentials provided by the binding to access the service instance")

		Eventually(Cf("unbind-service", appName, serviceInstanceName), defaultTimeout).Should(Exit(0))

		resp, _ = http.Get(instance_url)
		Expect(resp.StatusCode).To(Equal(403), "should not have been able to access the service instance using credentials from a deleted binding")

		Eventually(Cf("delete-service", "-f", serviceInstanceName), defaultTimeout).Should(Exit(0))

		resp, _ = http.Get(instance_url)
		Expect(resp.StatusCode).To(Equal(404), "should not have been able to access the service instance url for a deleted instance")
	})
})
