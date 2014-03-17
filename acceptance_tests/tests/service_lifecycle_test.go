package tests

import (
	"time"
	"math/rand"
	"fmt"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/vito/cmdtest/matchers"
	. "github.com/cloudfoundry-incubator/v1-dummy-broker-release/acceptance_tests/helpers"
	. "github.com/pivotal-cf-experimental/cf-test-helpers/cf"
)

var _ = Describe("Service Lifecycle", func(){
		BeforeEach(func(){
			LoginAsUser()
			rand.Seed( time.Now().UTC().UnixNano())
		})

		It("create service instance successfully", func(){
				serviceInstanceName := fmt.Sprintf("test-service-%d", rand.Intn(999999))
				Expect(Cf("services")).NotTo(Say(serviceInstanceName))
				//create service instance
				Expect(Cf("create-service", "v1-test", "free", serviceInstanceName)).To(ExitWithTimeout(0, 10*time.Second))
				//check that the service instance exists
				Expect(Cf("services")).To(Say(serviceInstanceName))
			})
	})
