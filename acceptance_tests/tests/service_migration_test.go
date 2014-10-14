package tests

import (
	. "github.com/cloudfoundry-incubator/cf-test-helpers/generator"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"

	helpers "../helpers"
)

var _ = Describe("Service Migration", func() {

	defaultTimeout := 60

	var v2ServiceBroker helpers.ServiceBroker

	BeforeEach(func() {
		serviceInstanceName := RandomName()

		Eventually(cf.Cf("create-service", environment.ServiceInfo.ServiceName, environment.ServiceInfo.PlanName, serviceInstanceName), defaultTimeout).Should(Exit(0))

		v2ServiceBroker = helpers.NewServiceBroker(RandomName(), helpers.NewAssets().V2ServiceBroker, environment.Context)
		v2ServiceBroker.Push()
		v2ServiceBroker.Configure()
		v2ServiceBroker.Create()
		v2ServiceBroker.PublicizePlans()
	})

	AfterEach(func() {
		v2ServiceBroker.Destroy()
	})

	It("Migrates V1 service instance to V2", func() {
		cf.AsUser(v2ServiceBroker.Context.AdminUserContext(), func() {
			Eventually(cf.Cf("migrate-service-instances", "-f",
				environment.ServiceInfo.ServiceName,
				environment.ServiceInfo.ServiceProvider,
				environment.ServiceInfo.PlanName,
				v2ServiceBroker.Service.Name,
				v2ServiceBroker.Plan.Name), defaultTimeout).Should(Exit(0))
		})
		services := cf.Cf("services")
		Eventually(services, defaultTimeout).Should(Exit(0))
		Expect(services.Out.Contents()).To(ContainSubstring(v2ServiceBroker.Plan.Name))
	})

})
