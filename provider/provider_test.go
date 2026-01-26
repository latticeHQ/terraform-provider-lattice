package provider_test

import (
	"testing"

	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/resource"
	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
	"github.com/hashicorp/terraform-plugin-sdk/v2/terraform"
	"github.com/stretchr/testify/require"

	"github.com/latticehq/terraform-provider-lattice/provider"
)

func TestProvider(t *testing.T) {
	t.Parallel()
	tfProvider := provider.New()
	err := tfProvider.InternalValidate()
	require.NoError(t, err)
}

// TestProviderEmpty ensures that the provider can be configured without
// any actual input data. This is important for adding new fields
// with backwards compatibility guarantees.
func TestProviderEmpty(t *testing.T) {
	t.Parallel()
	resource.Test(t, resource.TestCase{
		Providers: map[string]*schema.Provider{
			"wirtual": provider.New(),
		},
		IsUnitTest: true,
		Steps: []resource.TestStep{{
			Config: `
			provider "wirtual" {}
			data "lattice_provisioner" "me" {}
			data "lattice_workspace" "me" {}
			data "lattice_workspace_owner" "me" {}
			data "lattice_external_auth" "git" {
				id = "git"
			}
			data "lattice_git_auth" "git" {
				id = "git"
			}
			data "lattice_parameter" "param" {
				name = "hey"
			}`,
			Check: func(state *terraform.State) error {
				return nil
			},
		}},
	})
}
