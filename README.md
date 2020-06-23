# Hashicorp Vault AWS Integration

## Overview
The following blog describes Hashicorp Vault Integration in AWS. It focusses on three methods of accessing secrets in the
Vault. However the following implementations has a few assumptions as below. All the following options 

### Architecture Options
The following are the architecture option overviews
 - Option 1: Least Vault Maintenance Overhead
 - Option 2: Strictest Security Policies
 - Option 3: Least Effort for Consumers
 
### Assumptions:
 - The Vault instance is installed in AWS either in an EC2 instance or a docker container
 - The consumers are prepared only in Lambda
 - The Vault server mandates usage of https
 - This implementation doesn't need trusted TLS certificates
 - This Vault server URL needs to be publicly accessible. However, if this is not the case, the Lambda function needs to be modified to be attached to the VPC. 
 - There are 2 consumers for 2 namespace. The vault server, the namespace 1 and namespace 2 should be installed in 3 different accounts. So you would ideally require 2 different AWS accounts. At least, 1 AWS account separate from the Vault account.

 
## Overall Architecture
The following digram demonstrates the flow of the authentication, ticket and the usage of the ticket to getch secrets from Vault.

![Image](/architecture/AWS-vault.svg)

## Option 1

### Roles & Responsibilities

| Roles | Responsibilities | 
| --------------- | --------------- | 
| Consumer| <ul><li>Assume the Vault AWS Role</li><li>Add the relevant code to fetch secrets using the corresponding vault role</li></ul> | 
| Vault Instance Admin | <ul><li>Create the consumer IAM Role and trust the consumer account </li></ul>| 
| Vault Namespace Admin |  <ul><li>Add the newly created Consumer Role ARN in the `/auth.aws/role` path and bind the vault role/policy</li></ul>| 

![Image](/architecture/Vault_architecture-Option-1.svg)


## Option 2

![Image](/architecture/Vault_architecture-Option-2.svg)

***

## Option 3

![Image](/architecture/Vault_architecture-Option-3.svg)

***

## Demo

The following example demonstrates a Lambda function using 3 different accounts for Option 1, 2 and 3. 

### Prequisites 
The following steps are done for a macOS 10.13 or later. Please do the equivalent installs if you need to replicate on 
Windows or Linux. It uses AWS CloudFormation for SAM to deploy the above architecture


#### 1. Install the following tools
The following method shows installation using HomeBrew. However, other tools like macports otr direct
downloads can also be used. The following tools are needed
 - AWS CLI
 - AWS SAM CLI
 - Docker
 - Git
 - An Installed Hashicorp Vault Enterprise Version 0.12 or above

```commandline
brew tap aws/tap
brew install docker aws-cli aws-sam-cli git
```

#### 2. Prepare your AWS account config info, add all 3 accounts with their respective profile ids - vault, namespace_1, namespace_2

```commandline
$ aws configure
AWS Access Key ID [None]: your_access_key_id
AWS Secret Access Key [None]: your_secret_access_key
Default region name [None]: 
Default output format [None]: 
```


#### 3. Checkout Git repo
```commandline
git clone https://github.com/banroney/hvault-aws.git
```

> **Do Steps 4, 5, 6 for 2 AWS accounts -** 

#### 4. Build SAM
Fill out the following before executing the command
  - Replace `project_folder` with the location of the git checked-out folder.
  - Replace AWS_Account_Profile> with the targeted AWS account as per Step 2. 

```commandline
cd <project_folder> && \
sam build \
    —-profile <AWS_Account_Profile>
    --template template.yaml \
    --build-dir .aws-sam/build \
    --use-container
```


#### 5. Package SAM 
Provide your S3 bucket name that can be used to upload the built SAM package
 - Replace `<project_folder>` with the location of the git checked-out folder
 - Replace `<S3_bucket_Name>` wih the name of the bucket in the target profile to upload
 the built package to.
 - Replace AWS_Account_Profile> with the targeted AWS account as per Step 2. 

```commandline
cd <project_folder> && \
sam package \
    —-profile <AWS_Account_Profile>
    --template-file .aws-sam/build/template.yaml \
    --output-template-file .aws-sam/build/packaged-template.yaml \
    --s3-bucket <S3_bucket_Name>
```


#### 6. Deploy SAM
Replace the following before running the command
  - Replace `project_folder` with the location of the git checked-out folder.
  - Replace `<AWS_Account_Profile>` with the targeted AWS account as per Step 2. 
  - In the `parameter-overrides` section, please provide the details as mentioned below. 
    - Replace `Vault_account_id` with the AWS account ID for Vault. 
    - Replace `Vault_Chained_Base64_cert` with the Vault Certificate if not trusted
    - Replace `Vault_URL` with the targeted vault
    - Replace `Vault_NameSpace` with the targeted Enterprise Vault Namespace

```commandline
cd <project_folder> && \
sam deploy \
    —-profile <AWS_Account_Profile>
    --template-file .aws-sam/build/packaged-template.yaml \
    --stack-name hvault-aws \
    —capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --no-execute-changeset \
    --parameter-overrides \
       VaultAccountId=<Vault_account_id> \
       VaultCert=<Vault_Chained_Base64_cert> \
       VaultKvMount=kv \
       VaultSkipVerify=true \
       VaultAddr=<Vault_URL> \
       VaultNamespace=<Vault_NameSpace>
```
#### 7. Test and run the configuration

````json5
{
	"variable": [
		{
			"id": "2966d27c-cb24-40bf-93a5-6ef1460d2702",
			"key": "namespace",
			"value": "<insert your proposed namespace here>",
			"type": "string"
		},
		{
			"id": "a435036b-5176-45e9-bc29-1e655a575a33",
			"key": "trust_accountid",
			"value": "<insert AWS account id for namespace>",
			"type": "string"
		},
		{
			"id": "7c9fd632-4383-4366-b82f-52314ca3ef1e",
			"key": "consumer_role_arn",
			"value": "arn:aws:iam::<insert AWS account id for namespace>:role/HVaultOpt12FunctionRole",
			"type": "string"
		},
		{
			"id": "9b2b0ba8-179b-46db-8d14-21f3392413b9",
			"key": "local_role_arn",
			"value": "arn:aws:iam::<insert vault account id>:role/VaultRole_Opt3_CCenter",
			"type": "string"
		},
		{
			"id": "9a49dad7-7906-4aa6-86c5-beb7fd905c6a",
			"key": "vault_role_prefix",
			"value": "role",
			"type": "string"
		},
		{
			"id": "5c1f691e-fade-46ab-8880-279f5c1bc047",
			"key": "vault_url",
			"value": "insert your vault url in the format host:port. Do not include http or https",
			"type": "string"
		},
		{
			"id": "04af0373-5740-42d1-9586-9d43a1a69e5c",
			"key": "vault_token",
			"value": "s.FjoPtnm6sywkmDdtJEL3Mxyo",
			"type": "string"
		}
	]
}
````
