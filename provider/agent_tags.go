package provider

import (
	"context"

	"github.com/google/uuid"
	"github.com/hashicorp/terraform-plugin-sdk/v2/diag"
	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

type AgentTags struct {
	Tags map[string]string
}

func agentTagDataSource() *schema.Resource {
	return &schema.Resource{
		SchemaVersion: 1,

		Description: "Use this data source to configure agent tags to select provisioners.",
		ReadContext: func(ctx context.Context, rd *schema.ResourceData, i interface{}) diag.Diagnostics {
			rd.SetId(uuid.NewString())
			return nil
		},
		Schema: map[string]*schema.Schema{
			"tags": {
				Type:        schema.TypeMap,
				Description: `Key-value map with agent tags`,
				ForceNew:    true,
				Optional:    true,
				Elem:        &schema.Schema{Type: schema.TypeString},
			},
		},
	}
}
