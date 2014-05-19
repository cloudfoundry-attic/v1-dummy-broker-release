package helpers

import (
	"time"
	"fmt"

	"github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
)

type ServiceInfo struct {
	ServiceName string
	ServiceProvider string
	PlanName string
	ServiceAuthToken string
}

type SuiteContext interface {
	Setup()
	Teardown()

	AdminUserContext() cf.UserContext
	RegularUserContext() cf.UserContext
}

type Environment struct {
	Context SuiteContext
	originalCfHomeDir string
	currentCfHomeDir string
	ServiceInfo ServiceInfo
	Config IntegrationConfig
}

func NewEnvironment(context SuiteContext, serviceInfo ServiceInfo, config IntegrationConfig) *Environment {
	return &Environment{Context: context, ServiceInfo: serviceInfo, Config: config}
}

func (e *Environment) Setup() {
	e.Context.Setup()

	cf.AsUser(e.Context.AdminUserContext(), func() {
		setUpSpaceWithUserAccess(e.Context.RegularUserContext())
		createAuthToken(e.ServiceInfo)
	})

	e.originalCfHomeDir, e.currentCfHomeDir = cf.InitiateUserContext(e.Context.RegularUserContext())
	cf.TargetSpace(e.Context.RegularUserContext())
}

func (e *Environment) Teardown() {
	cf.RestoreUserContext(e.Context.RegularUserContext(), e.originalCfHomeDir, e.currentCfHomeDir)
	e.Context.Teardown()
}

func setUpSpaceWithUserAccess(uc cf.UserContext) {
	spaceSetupTimeout := 10
	Eventually(cf.Cf("create-space", "-o", uc.Org, uc.Space), spaceSetupTimeout).Should(Exit(0))
	Eventually(cf.Cf("set-space-role", uc.Username, uc.Org, uc.Space, "SpaceManager"), spaceSetupTimeout).Should(Exit(0))
	Eventually(cf.Cf("set-space-role", uc.Username, uc.Org, uc.Space, "SpaceDeveloper"), spaceSetupTimeout).Should(Exit(0))
	Eventually(cf.Cf("set-space-role", uc.Username, uc.Org, uc.Space, "SpaceAuditor"), spaceSetupTimeout).Should(Exit(0))
}

func createAuthToken(serviceInfo ServiceInfo) {
	createAuthTokenSession := cf.Cf("create-service-auth-token", serviceInfo.ServiceName, serviceInfo.ServiceProvider, serviceInfo.ServiceAuthToken)

	select {
	case <-createAuthTokenSession.Out.Detect("OK"):
	case <-createAuthTokenSession.Out.Detect("The service auth token label is taken"):
		fmt.Println("It is ok that the create-service-auth-token command failed.  This just means the token is already in place.")
	case <-time.After(60 * time.Second):
		ginkgo.Fail("Failed to create auth token")
	}
	createAuthTokenSession.Out.CancelDetects()
}
