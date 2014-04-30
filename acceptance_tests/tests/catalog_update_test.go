package tests

import (
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
	. "github.com/pivotal-cf-experimental/cf-test-helpers/cf"
)

var _ = Describe("Catalog Update", func() {
	defaultTimeout := 60

	It("adds its service offerings and plans to Cloud Controller", func() {
		// verify that the service and plan are currently in the catalog
		plans := Cf("marketplace").Wait(defaultTimeout).Out.Contents()
		Expect(plans).To(ContainSubstring(environment.ServiceInfo.ServiceName))
		Expect(plans).To(ContainSubstring(environment.ServiceInfo.PlanName))

		// delete the service and its plans (delete instances and bindings first)
		AsUser(environment.Context.AdminUserContext(), func() {
			Eventually(Cf("purge-service-offering", "v1-test", "-p", "pivotal-software", "-f"), defaultTimeout).Should(Exit(0))
		})

		plans = Cf("marketplace").Wait(defaultTimeout).Out.Contents()
		Expect(plans).NotTo(ContainSubstring(environment.ServiceInfo.ServiceName))
		Expect(plans).NotTo(ContainSubstring(environment.ServiceInfo.PlanName))

		// wait for broker to update cc with catalog, assert that the service and plan appear in CC with the correct information
		time.Sleep(time.Second * 90)

		plans = Cf("marketplace").Wait(defaultTimeout).Out.Contents()
		Expect(plans).To(ContainSubstring(environment.ServiceInfo.ServiceName))
		Expect(plans).To(ContainSubstring(environment.ServiceInfo.PlanName))
	})
})
