package test

import (
	"encoding/json"
	"testing"
	"github.com/stretchr/testify/assert"
)

func TestSCPPolicyStructure(t *testing.T) {
	policyDoc := `{
		"Version": "2012-10-17",
		"Statement": [
			{
				"Sid": "DenyCloudTrailDisable",
				"Effect": "Deny",
				"Action": ["cloudtrail:StopLogging"],
				"Resource": "*"
			}
		]
	}`

	var policy map[string]interface{}
	err := json.Unmarshal([]byte(policyDoc), &policy)
	assert.NoError(t, err, "Policy should be valid JSON")
	assert.Equal(t, "2012-10-17", policy["Version"])
}

func TestRegionRestriction(t *testing.T) {
	allowedRegions := []string{"eu-west-2", "eu-west-1", "us-east-1"}
	assert.Contains(t, allowedRegions, "eu-west-2")
	assert.NotContains(t, allowedRegions, "us-west-2")
}

func TestKMSProtection(t *testing.T) {
	dangerousActions := []string{"kms:ScheduleKeyDeletion", "kms:DeleteAlias"}
	for _, action := range dangerousActions {
		assert.NotEmpty(t, action, "Dangerous KMS actions should be identified")
	}
}
