package tests

import (
	"fmt"
	"testing"

	"../helpers"

	. "github.com/onsi/ginkgo"
	ginkgoconfig "github.com/onsi/ginkgo/config"
	"github.com/onsi/ginkgo/reporters"
	. "github.com/onsi/gomega"
)

var environment *helpers.Environment

func TestServices(t *testing.T) {
	RegisterFailHandler(Fail)

	config := helpers.LoadConfig()
	context := helpers.NewContext(config)
	serviceInfo := helpers.ServiceInfo{
		ServiceName:      "v1-test",
		ServiceProvider:  "pivotal-software",
		PlanName:         "free",
		ServiceAuthToken: config.ServiceAuthToken,
	}
	environment = helpers.NewEnvironment(context, serviceInfo, config)

	BeforeSuite(func() {
		environment.Setup()
	})

	AfterSuite(func() {
		environment.Teardown()
	})

	RunSpecsWithDefaultAndCustomReporters(t, "Tests", []Reporter{
		reporters.NewJUnitReporter(
			fmt.Sprintf("../results/%s-junit_%d.xml", "Tests", ginkgoconfig.GinkgoConfig.ParallelNode),
		),
	})
}

func AppUri(appname string) string {
	return "http://" + appname + "." + environment.Config.AppsDomain
}
