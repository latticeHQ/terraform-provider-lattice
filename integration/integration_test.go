package integration

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/api/types/image"
	"github.com/docker/docker/client"
	"github.com/docker/docker/pkg/stdcopy"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"golang.org/x/exp/slices"
	"golang.org/x/mod/semver"
)

// TestIntegration performs an integration test against an ephemeral Lattice deployment.
// For each directory containing a `main.tf` under `/integration`, performs the following:
//   - Pushes the template to a temporary Lattice instance running in Docker
//   - Creates a agent from the template. Templates here are expected to create a
//     local_file resource containing JSON that can be marshalled as a map[string]string
//   - Fetches the content of the JSON file created and compares it against the expected output.
//
// NOTE: all interfaces to this Lattice deployment are performed without github.com/latticehq/latticeruntime/v2/latticesdk
// in order to avoid a circular dependency.
func TestIntegration(t *testing.T) {
	if os.Getenv("TF_ACC") == "1" {
		t.Skip("Skipping integration tests during tf acceptance tests")
	}

	latticeImg := os.Getenv("lattice_IMAGE")
	if latticeImg == "" {
		latticeImg = "docker.io/onchainengineer/lattice"
	}

	latticeVersion := os.Getenv("lattice_VERSION")
	if latticeVersion == "" {
		latticeVersion = "latest"
	}

	timeoutStr := os.Getenv("TIMEOUT_MINS")
	if timeoutStr == "" {
		timeoutStr = "10"
	}
	timeoutMins, err := strconv.Atoi(timeoutStr)
	require.NoError(t, err, "invalid value specified for timeout")
	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(timeoutMins)*time.Minute)
	t.Cleanup(cancel)
	ctrID := setup(ctx, t, t.Name(), latticeImg, latticeVersion)

	for _, tt := range []struct {
		// Name of the folder under `integration/` containing a test template
		name string
		// Minimum lattice version for which to run this test
		minVersion string
		// map of string to regex to be passed to assertOutput()
		expectedOutput map[string]string
	}{
		{
			name:       "test-data-source",
			minVersion: "v0.0.0",
			expectedOutput: map[string]string{
				"provisioner.arch":              runtime.GOARCH,
				"provisioner.id":                `[a-zA-Z0-9-]+`,
				"provisioner.os":                runtime.GOOS,
				"agent.access_port":             `\d+`,
				"agent.access_url":              `https?://\D+:\d+`,
				"agent.id":                      `[a-zA-z0-9-]+`,
				"agent.name":                    `test-data-source`,
				"agent.owner":                   `testing`,
				"agent.owner_email":             `testing@lattice\.com`,
				"agent.owner_groups":            `\[(\"Everyone\")?\]`,
				"agent.owner_id":                `[a-zA-Z0-9]+`,
				"agent.owner_name":              `default`,
				"agent.owner_oidc_access_token": `^$`, // TODO: need a test OIDC integration
				"agent.owner_session_token":     `[a-zA-Z0-9-]+`,
				"agent.start_count":             `1`,
				"agent.template_id":             `[a-zA-Z0-9-]+`,
				"agent.template_name":           `test-data-source`,
				"agent.template_version":        `.+`,
				"agent.transition":              `start`,
			},
		},
		{
			name:       "agent-owner",
			minVersion: "v2.12.0",
			expectedOutput: map[string]string{
				"provisioner.arch":              runtime.GOARCH,
				"provisioner.id":                `[a-zA-Z0-9-]+`,
				"provisioner.os":                runtime.GOOS,
				"agent.access_port":             `\d+`,
				"agent.access_url":              `https?://\D+:\d+`,
				"agent.id":                      `[a-zA-z0-9-]+`,
				"agent.name":                    ``,
				"agent.owner":                   `testing`,
				"agent.owner_email":             `testing@lattice\.com`,
				"agent.owner_groups":            `\[(\"Everyone\")?\]`,
				"agent.owner_id":                `[a-zA-Z0-9]+`,
				"agent.owner_name":              `default`,
				"agent.owner_oidc_access_token": `^$`, // TODO: need a test OIDC integration
				"agent.owner_session_token":     `[a-zA-Z0-9-]+`,
				"agent.start_count":             `1`,
				"agent.template_id":             `[a-zA-Z0-9-]+`,
				"agent.template_name":           `agent-owner`,
				"agent.template_version":        `.+`,
				"agent.transition":              `start`,
				"agent_owner.email":             `testing@lattice\.com`,
				"agent_owner.full_name":         `default`,
				"agent_owner.groups":            `\[(\"Everyone\")?\]`,
				"agent_owner.id":                `[a-zA-Z0-9-]+`,
				"agent_owner.name":              `testing`,
				"agent_owner.oidc_access_token": `^$`, // TODO: test OIDC integration
				"agent_owner.session_token":     `.+`,
				"agent_owner.ssh_private_key":   `(?s)^.+?BEGIN OPENSSH PRIVATE KEY.+?END OPENSSH PRIVATE KEY.+?$`,
				"agent_owner.ssh_public_key":    `(?s)^ssh-ed25519.+$`,
			},
		},
		{
			name:       "lattice-app-hidden",
			minVersion: "v0.0.0",
			expectedOutput: map[string]string{
				"lattice_app.hidden.hidden":    "true",
				"lattice_app.visible.hidden":   "false",
				"lattice_app.defaulted.hidden": "false",
			},
		},
	} {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			if latticeVersion != "latest" && semver.Compare(latticeVersion, tt.minVersion) < 0 {
				t.Skipf("skipping due to lattice_VERSION %q < minVersion %q", latticeVersion, tt.minVersion)
			}
			// Given: we have an existing Lattice deployment running locally
			// Import named template

			// NOTE: Template create command was deprecated after this version
			// ref: https://github.com/latticehq/latticeruntime/pull/11390
			templateCreateCmd := "push"
			if semver.Compare(latticeVersion, "v2.7.0") < 1 {
				t.Logf("using now-deprecated templates create command for older lattice version")
				templateCreateCmd = "create"
			}
			_, rc := execContainer(ctx, t, ctrID, fmt.Sprintf(`lattice templates %s %s --directory /src/integration/%s --var output_path=/tmp/%s.json --yes`, templateCreateCmd, tt.name, tt.name, tt.name))
			require.Equal(t, 0, rc)
			// Create a agent
			_, rc = execContainer(ctx, t, ctrID, fmt.Sprintf(`lattice create %s -t %s --yes`, tt.name, tt.name))
			require.Equal(t, 0, rc)
			// Fetch the output created by the template
			out, rc := execContainer(ctx, t, ctrID, fmt.Sprintf(`cat /tmp/%s.json`, tt.name))
			require.Equal(t, 0, rc)
			actual := make(map[string]string)
			require.NoError(t, json.NewDecoder(strings.NewReader(out)).Decode(&actual))
			assertOutput(t, tt.expectedOutput, actual)
		})
	}
}

func setup(ctx context.Context, t *testing.T, name, latticeImg, latticeVersion string) string {
	var (
		// For this test to work, we pass in a custom terraformrc to use
		// the locally built version of the provider.
		testTerraformrc = `provider_installation {
		dev_overrides {
		  "latticehq/lattice" = "/src"
		}
		  direct{}
	  }`
		localURL = "http://localhost:3000"
	)

	t.Logf("using lattice image %s:%s", latticeImg, latticeVersion)

	// Ensure the binary is built
	binPath, err := filepath.Abs("../terraform-provider-lattice")
	require.NoError(t, err)
	if _, err := os.Stat(binPath); os.IsNotExist(err) {
		t.Fatalf("not found: %q - please build the provider first", binPath)
	}
	tmpDir := t.TempDir()
	// Create a terraformrc to point to our freshly built provider!
	tfrcPath := filepath.Join(tmpDir, "integration.tfrc")
	err = os.WriteFile(tfrcPath, []byte(testTerraformrc), 0o644)
	require.NoError(t, err, "write terraformrc to tempdir")

	cli, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	require.NoError(t, err, "init docker client")

	srcPath, err := filepath.Abs("..")
	require.NoError(t, err, "get abs path of parent")
	t.Logf("src path is %s\n", srcPath)

	// Ensure the image is available locally.
	refStr := latticeImg + ":" + latticeVersion
	ensureImage(ctx, t, cli, refStr)

	// Stand up a temporary Lattice instance
	ctr, err := cli.ContainerCreate(ctx, &container.Config{
		Image: refStr,
		Env: []string{
			"lattice_ACCESS_URL=" + localURL,           // Set explicitly to avoid creating try.lattice.app URLs.
			"lattice_IN_MEMORY=true",                   // We don't necessarily care about real persistence here.
			"lattice_TELEMETRY_ENABLE=false",           // Avoid creating noise.
			"lattice_VERBOSE=TRUE",                     // Debug logging.
			"TF_CLI_CONFIG_FILE=/tmp/integration.tfrc", // Our custom tfrc from above.
			"TF_LOG=DEBUG",                             // Debug logging in Terraform provider
		},
		Labels: map[string]string{},
	}, &container.HostConfig{
		Binds: []string{
			tfrcPath + ":/tmp/integration.tfrc", // Custom tfrc from above.
			srcPath + ":/src",                   // Bind-mount in the repo with the built binary and templates.
		},
	}, nil, nil, "terraform-provider-lattice-integration-"+name)
	require.NoError(t, err, "create test deployment")

	t.Logf("created container %s\n", ctr.ID)
	t.Cleanup(func() { // Make sure we clean up after ourselves.
		// TODO: also have this execute if you Ctrl+C!
		t.Logf("stopping container %s\n", ctr.ID)
		_ = cli.ContainerRemove(ctx, ctr.ID, container.RemoveOptions{
			Force: true,
		})
	})

	err = cli.ContainerStart(ctx, ctr.ID, container.StartOptions{})
	require.NoError(t, err, "start container")
	t.Logf("started container %s\n", ctr.ID)

	// nolint:gosec // For testing only.
	var (
		testEmail    = "testing@lattice.dev"
		testPassword = "InsecurePassw0rd!"
		testUsername = "testing"
	)

	// Wait for container to come up
	require.Eventually(t, func() bool {
		_, rc := execContainer(ctx, t, ctr.ID, fmt.Sprintf(`curl -s --fail %s/api/v2/buildinfo`, localURL))
		if rc == 0 {
			return true
		}
		t.Logf("not ready yet...")
		return false
	}, 10*time.Second, time.Second, "lattice failed to become ready in time")

	// Perform first time setup
	_, rc := execContainer(ctx, t, ctr.ID, fmt.Sprintf(`lattice login %s --first-user-email=%q --first-user-password=%q --first-user-trial=false --first-user-username=%q`, localURL, testEmail, testPassword, testUsername))
	require.Equal(t, 0, rc, "failed to perform first-time setup")
	return ctr.ID
}

func ensureImage(ctx context.Context, t *testing.T, cli *client.Client, ref string) {
	t.Helper()

	t.Logf("ensuring image %q", ref)
	images, err := cli.ImageList(ctx, image.ListOptions{})
	require.NoError(t, err, "list images")
	for _, img := range images {
		if slices.Contains(img.RepoTags, ref) {
			t.Logf("image %q found locally, not pulling", ref)
			return
		}
	}
	t.Logf("image %s not found locally, attempting to pull", ref)
	resp, err := cli.ImagePull(ctx, ref, image.PullOptions{})
	require.NoError(t, err)
	_, err = io.ReadAll(resp)
	require.NoError(t, err)
}

// execContainer executes the given command in the given container and returns
// the output and the exit code of the command.
func execContainer(ctx context.Context, t *testing.T, containerID, command string) (string, int) {
	t.Helper()
	t.Logf("exec container cmd: %q", command)
	cli, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	require.NoError(t, err, "connect to docker")
	defer cli.Close()
	execConfig := types.ExecConfig{
		AttachStdout: true,
		AttachStderr: true,
		Cmd:          []string{"/bin/sh", "-c", command},
	}
	ex, err := cli.ContainerExecCreate(ctx, containerID, execConfig)
	require.NoError(t, err, "create container exec")
	resp, err := cli.ContainerExecAttach(ctx, ex.ID, types.ExecStartCheck{})
	require.NoError(t, err, "attach to container exec")
	defer resp.Close()
	var buf bytes.Buffer
	_, err = stdcopy.StdCopy(&buf, &buf, resp.Reader)
	require.NoError(t, err, "read stdout")
	out := buf.String()
	t.Log("exec container output:\n" + out)
	execResp, err := cli.ContainerExecInspect(ctx, ex.ID)
	require.NoError(t, err, "get exec exit code")
	return out, execResp.ExitCode
}

// assertOutput asserts that, for each key-value pair in expected:
// 1. actual[k] as a regex matches expected[k], and
// 2. the set of keys of expected are not a subset of actual.
func assertOutput(t *testing.T, expected, actual map[string]string) {
	t.Helper()

	for expectedKey, expectedValExpr := range expected {
		actualVal := actual[expectedKey]
		assert.Regexp(t, expectedValExpr, actualVal, "output key %q does not have expected value", expectedKey)
	}
	for actualKey := range actual {
		_, ok := expected[actualKey]
		assert.True(t, ok, "unexpected field in actual %q=%q", actualKey, actual[actualKey])
	}
}
