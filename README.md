# Cloud Foundry V1 Dummy Broker Service

This project contains a BOSH release of a dummy broker that implements the minimum functionality of a v1 service broker.

## Installation

Prerequisites:

- A deployment of Cloud Foundry ([cf-release](https://github.com/cloudfoundry/cf-release))
- Installing the dummy broker service requires BOSH.
- Instructions on installing BOSH as well as Cloud Foundry (runtime) are located in the [Cloud Foundry documentation](http://docs.cloudfoundry.org).

Steps:

1. Create a deployment manifest
1. Create a BOSH release
1. Upload the release to the BOSH director
1. Deploy the release with BOSH
1. Make the plan public

The dummy broker service should now be advertised when running `cf marketplace`

### Generating a Deployment Manifest

We have provided scripts to help you generate a deployment manifest.  These scripts currently support AWS, and [bosh-lite](https://github.com/cloudfoundry/bosh-lite) deployments.

The scripts we provide require [Spiff](https://github.com/cloudfoundry-incubator/spiff) to be installed on the local workstation.  Spiff is a tool we use to help generate a deployment manifest from "stubs", YAML files with values unique to the deployment environment (two identical deployments of Cloud Foundry will have stubs with the same keys but some unique values).

To generate a deployment manifest for bosh-lite, follow the instructions [here](#using-bosh-lite).

To generate a deployment manifest for AWS use the [generate_deployment_manifest](generate_deployment_manifest) script.  We recommend the following workflow:

1. Run the `generate_deployment_manifest` script. You'll get some error that indicates what the missing manifest parameters are.
1. Add those parameters and values into the stub.
1. Rinse and repeat
1. When all necessary stub parameters are present, the script will output the deployment manifest to stdout. Pipe this output to a file in your environment directory which indicates the environment and the release, such as `~/workspace/deployments/mydevenv/cf-mysql-mydevenv.yml`.

#### Example using AWS:
    $ ./generate_deployment_manifest aws ~/workspace/deployments/mydevenv/stub.yml

    2014/03/10 17:40:46 error generating manifest: unresolved nodes:
      (( .properties.v1-dummy-broker.uaa_client_auth_credentials.username ))	in dynaml	jobs.[0].properties.env.uaa_username
      (( .properties.v1-dummy-broker.uaa_client_auth_credentials.password ))	in dynaml	jobs.[0].properties.env.uaa_password
      (( merge ))	in ./templates/v1-dummy-broker.yml	properties.v1-dummy-broker

These errors indicate that the deployment manifest stub is missing the following fields:

    ---
    properties:
      v1-dummy-broker:
        uaa_client_auth_credentials:
          username: <username>
          password: <password>

#### For AWS:

You need to know the AZ and subnet id, and you will need to configure them in the stub:

- `availability_zone`: From the EC2 page of the AWS console, like `us-east-1a`.
- `subnet_id`:  From VPC/Subnets page of AWS console.  Availability zone must match the value set above.

#### Using bosh-lite

Running the [make_manifest](bosh-lite/make_manifest) script requires that you have bosh-lite installed and running on your local workstation.  Instructions for doing that can be found on the [bosh-lite README](https://github.com/cloudfoundry/bosh-lite).

For bosh-lite we provide a fully configured [stub](bosh-lite/v1-dummy-broker-stub.yml)

Run the `make_manifest` script to generate your manifest, which you can find in [v1-dummy-broker-release/bosh-lite/](bosh-lite/).

Example:
```
$ ./bosh-lite/make_manifest
# This step would have also set your deployment to ./bosh-lite/manifests/v1-dummy-broker-manifest.yml
```

### Create a BOSH Release

To build the release from HEAD:

    $ ./update
    $ bosh create release

When prompted to name the release, call it `v1-dummy-broker`.

### Upload Release

    $ bosh upload release

### Deploy Using BOSH

Set your deployment using the deployment manifest you generated above.

    $ bosh deployment ~/workspace/deployments/mydevenv/v1-dummy-broker-mydevenv.yml
    $ bosh deploy
    
#### Deploy to bosh-lite

If you followed the instructions for bosh-lite above your manifest is `v1-dummy-broker-release/bosh-lite/manifests/v1-dummy-broker-mydevenv.yml`. The `make_manifest` script should have already set the deployment to this manifest, so you just have to run:

    $ bosh deploy
