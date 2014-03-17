package helpers

import (
	"github.com/vito/cmdtest"
	"github.com/pivotal-cf-experimental/cf-test-helpers/cf"
)

func CallingCf(command string) func() *cmdtest.Session {
	return func() *cmdtest.Session {
		return cf.Cf(command)
	}
}
