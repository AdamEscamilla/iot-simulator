# IoT Simulator

A IoT device simulation platform built from scratch on Google Cloud Platform. The application simulates sending data from a device to the cloud.

## Architecture

This solution builds the minimal set of infrastructure components to utilize Google IoT Core service.

Following components are used:
* IoT Core
* Pub/Sub
* Compute

## Prerequisites

* [Git](https://git-scm.com/downloads)
* [Terraform](https://www.terraform.io/downloads.html)
* [Google Cloud Account](https://cloud.google.com/free/docs/gcp-free-tier)

## Setup

### Create Project

1. [Create a project](https://console.cloud.google.com/projectcreate)
2. Give it a name and click 'Create'
3. [Select the new project](https://console.cloud.google.com/projectselector2)

**note the project ID as it can differ from the name and is auto-generated. we will use it later in the configuration section**

### Create Service Account

1. [Create Service Account](https://console.cloud.google.com/iam-admin/serviceaccounts/create)
2. Assign the Editor Role.
3. Download the key. Under 'Actions', click on the kebab drop down menu and click 'Create key'. The JSON key type should be selected, and click 'CREATE'. This will download the credentials file to your computer. Note the storage location so we can set the variable 'GOOGLE_CREDENTIALS' to that path.

**note the service account name does NOT matter but we will be using the credentials key file when creating the infrastructure**

### Configuration

This is the configuration I'll be using for this setup:
```
PROJECT_NAME="iot-simulator"
PROJECT_ID="iot-simulator-295301"
REGION="us-central1"
REGISTRY_ID="iot-simulator-registry"
DEVICE_ID="iot-simulator-device"
KEY_PATH="./client.key"
ALGORITHM="RS256"
ROOT_PATH="./ca.crt"
```

### Create Infrastructure

Start by cloning into this repo
```sh
git clone https://github.com/adamescamilla/iot-simulator
cd iot-simulator/terraform
```

Rename the terraform configuration file. And replace variable string with your actual project ID noted from above.
```
mv terraform.tfvars.sample terraform.tfvars
```

Set the environment for terraform to pickup our credentials
```sh
GOOGLE_CREDENTIALS=~/Downloads/iot-simulator-295301-a7b9851c1c7e.json
GOOGLE_REGION="us-central1"
GOOGLE_ZONE="us-central1-a"
export GOOGLE_CREDENTIALS GOOGLE_REGION GOOGLE_ZONE
```

Now we run terraform to create the infrastructure
```sh
terraform init
terraform plan
terraform apply
```

After that is finished running we should have an IP we can access similar to `Outputs: instance_ip = 35.209.241.83`

## Finish Setup

The rest of these steps are mostly manual to demonstrate how we might simulate our own applications.

The sample app we'll be using is written in c and is used to make client connect to Google IoT using the MQTT protocol.

### Finish server setup

Ensure we have ssh keys available to login
```sh
file ~/.ssh/id_rsa
```

If the above command shows the file is missing you can generate a key using the following command
```sh
ssh-keygen -q -b 2048 -t rsa -N "" -f ~/.ssh/id_rsa
```
Now we can login to our server to finish the provisioning
```sh
ssh ubuntu@35.209.241.83
```

We'll clone the repo again to pull down our configs and move into that directory
```sh
git clone https://github.com/adamescamilla/iot-simulator
cd iot-simulator
```

Run the provisioning script that sets up our server dependencies
```
chmod +x install.sh
./install.sh
```

We'll start by authorizing with GCP using the google cloud sdk Docker image.
```sh
sudo docker run -it --name auth google/cloud-sdk:alpine gcloud auth login
```

Follow the OAuth2 link to your browser and copy the code back into the terminal.

Let's start that container so we can issue more commands to it.
```sh
sudo docker start auth
```

And to simplify further commands we'll create an alias
```sh
alias gcloud="sudo docker exec -it auth gcloud"
```

Create the Pub/Sub topic to ingest our data
```sh
gcloud pubsub topics create iot-simulator-topic
```

Create the topic pull subscription
```sh
gcloud pubsub subscriptions create iot-simulator-subscription --topic=iot-simulator-topic
```
Create the device registry
```sh
gcloud iot registries create iot-simulator-registry --region=us-central1 --event-notification-config=topic=iot-simulator-topic
```

Create and register a device
```sh
openssl req -x509 -newkey rsa:2048 -keyout device/client.key -nodes -out device/client.crt -subj "/CN=client"
```

We'll inject our cert as the container is running
```sh
sudo docker exec -it auth sh -c "echo \"`cat ./device/client.crt`\" >/tmp/client.crt"
gcloud iot devices create iot-simulator-device --region=us-central1 --registry=iot-simulator-registry --public-key="path=/tmp/client.crt,type=rs256"
```

With all that we now have everything we need in the cloud to start communicating. Now we will poceed to create a local device to start generating telemetry data.

### Build MQTT client

Create the simulated device container
```sh
cd device
sudo docker build -t iot-device .
```

**note above command takes about ~45 minutes for first time build on the free f1-micro instance**

### Run MQTT client

Source the config to populate the environment with our settings
```sh
source config
```

**note ensure you have the proper settings and the project ID matches exactly**

Now we can publish a message into our pipeline
```sh
sudo docker run -it --rm iot-device sh -c "./mqtt_client 'test message' --deviceid $DEVICE_ID --region $REGION --registryid $REGISTRY_ID --projectid $PROJECT_ID --keypath $KEY_PATH --algorithm $ALGORITHM --rootpath $ROOT_PATH"
```

The output of that command should look similar to this
```
New client id constructed:
projects/iot-simulator/locations/us-central1/registries/iot-simulator-registry/devices/iot-simulator-device
Topic constructed:
/devices/iot-simulator-device/events
IAT: 1604981604
EXP: 1604985204
JWT: [eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpb3Qtc2ltLXByb2plY3QxIiwiZXhwIjoiMTYwNDk4NTIwNCIsImlhdCI6IjE2MDQ5ODE2MDQifQ.XT5JnoVlhGKBNjCNkDhb6pHPFA1E-uvWFBokBMHblcDbuwOa6OxfomRU5KlHVrPTpBbKrjnXdBfAc-9ZW0izCuRSgNECRXe1NqPdGisIYO3qVUGtWaM9LkV56V6CKzg0Rn-jhyB179d7mA0T1FwnDZfgrs4pGZ4bb7oWtDjQmgFB5GyPOvyCHe9H1JYDjTuvfnHNizPQtQg5PLfusMfQu9Gwxgi5_m_M6uaC3xH2HYL0ENw3-Az0noWmO4yAKR6Xzq3hu7ZlJm_bAj7llFUrcJnqbRUvUexRz4LKDKFpTYbTBCbCUrdfDgm5IOa0iudY7bVAjOSHUJRGJwvAmkH7ZQ]
Waiting for up to 10 seconds for publication of test message
on topic /devices/iot-simulator-device/events for client with ClientID: projects/iot-simulator/locations/us-central1/registries/iot-simulator-registry/devices/iot-simulator-device
Message with delivery token 1 delivered
```

### Test Telemetry

Check if we received the message on the other end of our pipeline
```sh
gcloud pubsub subscriptions pull --limit=1 iot-simulator-subscription
```

That's it!

We'll expand on this and see what other IoT images we can install and develop on.

## Clean up

To clean up the environment exit the ssh session by typing `exit` and run `terraform destroy` to remove all the services we created.
```sh
exit
terraform destroy
```

## Roadmap

* replace gcloud cli commands with terraform modules
