package terratest

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformAzureBasic(t *testing.T) {
	t.Parallel()

	uniqueId := "terratest123"

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../../terraform/azure_basic",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"unique_id": uniqueId,
		},

		// Disable colors in Terraform commands so its easier to parse stdout/stderr
		NoColor: true,
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables
	output_ssh_command := terraform.Output(t, terraformOptions, "host_bastion_SSH_command")
	output_admin_password := terraform.Output(t, terraformOptions, "host_bastion_admin_password")

	// Verify we're getting back the outputs we expect
	assert.Contains(t, output_ssh_command, "ssh -A")
	assert.Equal(t, len(output_admin_password), 12)
}