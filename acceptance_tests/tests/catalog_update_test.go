package tests

import (
	"fmt"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
	. "github.com/pivotal-cf-experimental/cf-test-helpers/cf"
)

var _ = Describe("Catalog Update", func() {
	defaultTimeout := 60

	It("adds its service offerings and plans to Cloud Controller", func() {
		serviceOfferingRegex := fmt.Sprintf("%s.*%s", environment.ServiceInfo.ServiceName, environment.ServiceInfo.PlanName)

		// verify that the service and plan are currently in the catalog
		plans := Cf("marketplace").Wait(defaultTimeout).Out.Contents()
		Expect(plans).To(MatchRegexp(serviceOfferingRegex))

		// delete the service and its plans (delete instances and bindings first)
		AsUser(environment.Context.AdminUserContext(), func() {
			Eventually(Cf("purge-service-offering", "v1-test", "-p", "pivotal-software", "-f"), defaultTimeout).Should(Exit(0))
		})

		plans = Cf("marketplace").Wait(defaultTimeout).Out.Contents()
		Expect(plans).NotTo(MatchRegexp(serviceOfferingRegex))

		Expect(serviceIsPopulated(serviceOfferingRegex)).To(Equal(true), "Cloud Controller was not populated with the expected service offering.")
	})
})

// a v1 broker periodically broadcasts service offerings.
// wait some period of time for the offering to appear in Cloud Controller
func serviceIsPopulated(serviceOfferingRegex string) bool {
	var marketplaceSession *Session
	var retryInterval time.Duration = 20 * time.Second
	retryAttempts := 10
	foundServiceOffering := false

retryLoop:
	for attempt := 1; attempt <= retryAttempts; attempt++ {
		marketplaceSession = Cf("marketplace")

		select {
		case <-marketplaceSession.Out.Detect(serviceOfferingRegex):
			foundServiceOffering = true
			break retryLoop
		case <-time.After(retryInterval):
		}
		marketplaceSession.Out.CancelDetects()
	}

	return foundServiceOffering
}
