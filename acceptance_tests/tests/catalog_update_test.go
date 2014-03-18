package tests

import (
	. "github.com/cloudfoundry-incubator/v1-dummy-broker-release/acceptance_tests/helpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/pivotal-cf-experimental/cf-test-helpers/cf"
	. "github.com/vito/cmdtest/matchers"
	"time"
)

var _ = Describe("Catalog Update", func() {
	BeforeEach(func() {
		LoginAsAdmin()
	})

	It("adds its service offerings and plans to Cloud Controller", func() {
		// verify that the service and plan are currently in the catalog
		session := Cf("marketplace")
		Expect(session).To(Say("v1-test.*free"))
		// delete the service and its plans (delete instances and bindings first)
		Expect(Cf("purge-service-offering", "v1-test", "-p", "pivotal-software", "-f")).To(ExitWithTimeout(0, 10*time.Second))
		Expect(session).NotTo(Say("v1-test.*free"))

		// with retry and a 90s timeout, assert that the service and plan appear in CC with the correct information
		Eventually(CallingCf("marketplace"), 90, 5).Should(Say("v1-test.*free"))
	})
})
