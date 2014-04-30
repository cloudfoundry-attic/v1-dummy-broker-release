package helpers

import (
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/pivotal-cf-experimental/cf-test-helpers/cf"
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
		Eventually(cf.Cf("create-service-auth-token", e.ServiceInfo.ServiceName, e.ServiceInfo.ServiceProvider, e.ServiceInfo.ServiceAuthToken), 60).Should(Exit(0))
	})

	e.originalCfHomeDir, e.currentCfHomeDir = cf.InitiateUserContext(e.Context.RegularUserContext())
	cf.TargetSpace(e.Context.RegularUserContext())
}

func (e *Environment) Teardown() {
	e.Context.Teardown()

	cf.AsUser(e.Context.AdminUserContext(), func() {
		Eventually(cf.Cf("delete-service-auth-token", e.ServiceInfo.ServiceName, e.ServiceInfo.ServiceProvider, "-f"), 60).Should(Exit(0))
	})

	cf.RestoreUserContext(e.Context.RegularUserContext(), e.originalCfHomeDir, e.currentCfHomeDir)
}

func setUpSpaceWithUserAccess(uc cf.UserContext) {
	spaceSetupTimeout := 10
	Eventually(cf.Cf("create-space", "-o", uc.Org, uc.Space), spaceSetupTimeout).Should(Exit(0))
	Eventually(cf.Cf("set-space-role", uc.Username, uc.Org, uc.Space, "SpaceManager"), spaceSetupTimeout).Should(Exit(0))
	Eventually(cf.Cf("set-space-role", uc.Username, uc.Org, uc.Space, "SpaceDeveloper"), spaceSetupTimeout).Should(Exit(0))
	Eventually(cf.Cf("set-space-role", uc.Username, uc.Org, uc.Space, "SpaceAuditor"), spaceSetupTimeout).Should(Exit(0))
}
