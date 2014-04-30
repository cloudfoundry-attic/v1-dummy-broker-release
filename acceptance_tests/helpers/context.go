package helpers

import (
	"fmt"
	"time"

	ginkgoconfig "github.com/onsi/ginkgo/config"
	"github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
	"github.com/pivotal-cf-experimental/cf-test-helpers/cf"
)

type ConfiguredContext struct {
	config IntegrationConfig

	organizationName string
	spaceName        string
	quotaDefinitionName string

	regularUserUsername string
	regularUserPassword string
}

type quotaDefinition struct {
	Name string

	TotalServices string
	TotalRoutes   string
	MemoryLimit   string

	NonBasicServicesAllowed bool
}

func NewContext(config IntegrationConfig) *ConfiguredContext {
	node := ginkgoconfig.GinkgoConfig.ParallelNode
	timeTag := time.Now().Format("2006_01_02-15h04m05.999s")

	return &ConfiguredContext{
		config: config,

		organizationName: fmt.Sprintf("V1DummyATS-ORG-%d-%s", node, timeTag),
		spaceName:        fmt.Sprintf("V1DummyATS-SPACE-%d-%s", node, timeTag),
		quotaDefinitionName: fmt.Sprintf("V1DummyATS-QUOTA-%d-%s", node, timeTag),

		regularUserUsername: fmt.Sprintf("V1DummyATS-USER-%d-%s", node, timeTag),
		regularUserPassword: "meow",
	}
}

func (context *ConfiguredContext) Setup() {
	cf.AsUser(context.AdminUserContext(), func() {

		definition := createQuotaDefinition(context)

		createUserSession := cf.Cf("create-user", context.regularUserUsername, context.regularUserPassword)

		select {
		case <-createUserSession.Out.Detect("OK"):
		case <-createUserSession.Out.Detect("scim_resource_already_exists"):
		case <-time.After(30 * time.Second):
			ginkgo.Fail("Failed to create user")
		}
		createUserSession.Out.CancelDetects()

		Eventually(cf.Cf("create-org", context.organizationName), 60).Should(Exit(0))
		Eventually(cf.Cf("set-quota", context.organizationName, definition.Name), 60).Should(Exit(0))
	})
}

func (context *ConfiguredContext) Teardown() {
	cf.AsUser(context.AdminUserContext(), func() {
		Eventually(cf.Cf("delete-user", "-f", context.regularUserUsername), 60).Should(Exit(0))
		Eventually(cf.Cf("delete-org", "-f", context.organizationName), 60).Should(Exit(0))
		Eventually(cf.Cf("delete-quota", "-f", context.quotaDefinitionName), 60).Should(Exit(0))
	})
}

func (context *ConfiguredContext) AdminUserContext() cf.UserContext {
	return cf.NewUserContext(
		context.config.ApiEndpoint,
		context.config.AdminUser,
		context.config.AdminPassword,
		"",
		"",
		context.config.SkipSSLValidation,
	)
}

func (context *ConfiguredContext) RegularUserContext() cf.UserContext {
	return cf.NewUserContext(
		context.config.ApiEndpoint,
		context.regularUserUsername,
		context.regularUserPassword,
		context.organizationName,
		context.spaceName,
		context.config.SkipSSLValidation,
	)
}

func createQuotaDefinition(context *ConfiguredContext) quotaDefinition {
	definition := quotaDefinition{
		Name: context.quotaDefinitionName,

		TotalServices: "100",
		TotalRoutes:   "1000",
		MemoryLimit:   "10G",

		NonBasicServicesAllowed: true,
	}

	args := []string{
		"create-quota",
		context.quotaDefinitionName,
		"-m", definition.MemoryLimit,
		"-r", definition.TotalRoutes,
		"-s", definition.TotalServices,
	}
	if definition.NonBasicServicesAllowed {
		args = append(args, "--allow-paid-service-plans")
	}

	Eventually(cf.Cf(args...), 60).Should(Exit(0))

	return definition
}
