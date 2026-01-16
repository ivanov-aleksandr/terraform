package test

import (
	"fmt"
	"flag"
	"testing"
	"os"
	
	"github.com/gruntwork-io/terratest/modules/terraform"
    test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"golang.org/x/crypto/ssh"
)

var folder = flag.String("folder", "", "Folder ID in Yandex.Cloud")
var sshKeyPath = flag.String("ssh-key-pass", "", "Private ssh key for access to virtual machines")

func TestEndToEndDeploymentScenario(t *testing.T) {
    fixtureFolder := "../"

    test_structure.RunTestStage(t, "setup", func() {
		terraformOptions := &terraform.Options{
			TerraformDir: fixtureFolder,

			Vars: map[string]interface{}{
			"yc_folder":    *folder,
		    },
	    }

		test_structure.SaveTerraformOptions(t, fixtureFolder, terraformOptions)

		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "validate", func() {
	    fmt.Println("Run some tests...")
	    terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)

        // test load balancer ip existing
	    loadbalancerOutput := terraform.Output(t, terraformOptions, "load_balancer_external_ips")

	    // Преобразуем вывод в нужный формат
	    // loadbalancerOutput будет строкой, которую нужно распарсить
	    fmt.Printf("Load balancer output: %v\n", loadbalancerOutput)
	    
	    // убедимся что вывод не пустой
	    if loadbalancerOutput == "" {
	        t.Error("Cannot retrieve the public IP address value for the load balancer.")
	    } else {
	        fmt.Printf("✓ Load balancer output exists\n")
	    }

		// test ssh connect - получение IP адреса
		instanceIPsMap := terraform.OutputMap(t, terraformOptions, "instance_ips")
		
		if len(instanceIPsMap) == 0 {
			t.Fatal("No instance IPs available")
		}
		
		// первый доступный IP
		var vmLinuxPublicIPAddress string
		for _, ip := range instanceIPsMap {
			vmLinuxPublicIPAddress = ip
			break
		}
		
		fmt.Printf("Testing SSH connection to: %s\n", vmLinuxPublicIPAddress)

		key, err := os.ReadFile(*sshKeyPath)
		if err != nil {
			t.Fatalf("Unable to read private key: %v", err)
		}

		signer, err := ssh.ParsePrivateKey(key)
		if err != nil {
			t.Fatalf("Unable to parse private key: %v", err)
		}

		sshConfig := &ssh.ClientConfig{
			User: "ubuntu",
			Auth: []ssh.AuthMethod{
				ssh.PublicKeys(signer),
			},
			HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		}

		sshConnection, err := ssh.Dial("tcp", fmt.Sprintf("%s:22", vmLinuxPublicIPAddress), sshConfig)
		if err != nil {
			t.Fatalf("Cannot establish SSH connection to vm-linux public IP address: %v", err)
		}

		defer sshConnection.Close()
        
		sshSession, err := sshConnection.NewSession()
		if err != nil {
			t.Fatalf("Cannot create SSH session to vm-linux public IP address: %v", err)
		}

		defer sshSession.Close()
        
		err = sshSession.Run("ping -c 1 8.8.8.8")
		if err != nil {
			t.Fatalf("Cannot ping 8.8.8.8: %v", err)
		}
		
		fmt.Println("✓ SSH connection and ping test passed")

		// Test: Check database info
		dbInfo := terraform.OutputMap(t, terraformOptions, "db_info")
		if len(dbInfo) == 0 {
			t.Error("Database information not available")
		} else {
			fmt.Println("✓ Database information available")
		}
		
		fmt.Println("✓ All validations passed!")
   

    })

	test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)
		terraform.Destroy(t, terraformOptions)
	})
}