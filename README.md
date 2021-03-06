# Hashicorp Vault AWS Integration Scenarios

There are 2 modules in this repository, the first one explains the IAM authentication modes and how to use them without using harcoded credentials in Vault config. The second one focuses on how to synchronize Vault Items to AWS Secrets Manager.

## 1. Hashicorp Vault IAM Authentication

## 1.1 Overview
The following blog describes Hashicorp Vault Integration in AWS. It focusses on three methods of accessing secrets in the
Vault. However the following implementations has a few assumptions as below. All the following options 

### 1.1.1 Architecture Options
The following are the architecture option overviews
 - Option 1: Least Vault Maintenance Overhead
 - Option 2: Strictest Security Policies
 - Option 3: Least Effort for Consumers
 
### 1.1.2 Assumptions:
 - The Vault instance is installed in AWS either in an EC2 instance or a docker container
 - The consumers are prepared only in Lambda
 - The Vault server mandates usage of https
 - This implementation doesn't need trusted TLS certificates
 - This Vault server URL needs to be publicly accessible. However, if this is not the case, the Lambda 
   function needs to be modified to be attached to the VPC. 
 - There are 2 consumers for 2 namespace. The vault server, the namespace 1 and namespace 2 should be
   installed in 3 different accounts. So you would ideally require 2 different AWS accounts. At least, 1
   AWS account separate from the Vault account.

 
## 1.2 Architecture
The following diagram demonstrates the flow of the authentication, ticket and the usage of the ticket t
get secrets from the Vault. The key principle to the Vault not needing the AWS credentials as a part of the 
configuration is that, the instance or the container running assumes an AWS role that allows the vault to access the 
temporary credentials from STS and use them to carry out specific operations. However, one might notice that neither the
credentials, nor the instance profile is not needed for the Vault server to actually access the keys. The reason for 
that is Vault fetches AWS Signature V4 Authorization Header and the targeted STS server as per configuration (If this 
isn't configured, it uses https://sts.amazonaws.com/) from the consumer to assume the role and run `iam:getCallerIdentity`. 
The return value is matched against the configuration database and the secret is allowed to if the principals and the 
policies add up. 

However, while configuring, it needs to be done from the the Vault CLI and there if there is no client that can generate
AWS Signature V4 Authorization Header, the vault will fail to add the Role ID and the name to the vault configuration database. 
This is the reason of the above anomaly. 

The following diagram demonstrates how the IAM authentication happens from a Lambda function to a Vault instance and the
token is used in future conversations, until it expires. The renewal of the token happens outside the scope of this
document.


![Image](/architecture/AWS-vault.svg)

## 1.3 Option 1

### 1.3.1 Overview
In this option, the focus is on least effort on the Vault Namespace Administrator. In this method as shown in the picture
below, the Vault assumes the instance profile and add the trusted roles that can access certain secret areas and associate
policies with them. However the vault doesn't need to do any change at an AWS account level. 

The Vault EC2 Instance uses the following instance profile as shown below. Note that the Vault is capable if assuming any role in any AWS
account as long as the target role has a tag `vault-access=vault_aws_account_id`. This is a harmless asterix since, it 
cannot really assume any role unless the target account explicitly trusts the vault account. 

The target (consumer) account role has to explicitly trust the Vault account and needs to be use the exact role in order to
access vault secrets. 


### 1.3.2 AWS Policies

- The Vault Instance Profile policy
```json5
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::*:role/HVault*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/vault-access": "<your vault AWS account id>"
                }
            }
        }
    ]
}
```

- The Consumer Lambda Policy that is needed for vault access
```yaml
- PolicyName: vault_policy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action: iam:GetRole
                Resource: !Sub 'arn:aws:iam::${AWS::AccountId}:role/HVaultOpt12FunctionRole'
              - Effect: Allow
                Action: sts:GetCallerIdentity
                Resource: '*'
```
- The Consumer Lambda Assume Policy Document (Trusting Vault)
```yaml
AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - lambda.amazonaws.com
              AWS: !Sub
                - arn:aws:iam::${vaultaccountid}:root
                - { vaultaccountid: !Ref VaultAccountId}
            Action:
              - sts:AssumeRole
```


### 1.3.3 Roles & Responsibilities

| Roles | Responsibilities | 
| --------------- | --------------- | 
| Consumer| <ul><li>Attach the vault policy in the Lambda Execution Role</li><li>Add the relevant code to fetch secrets using the vault role (not AWS Role)</li><li>Trust the vault account</li></ul> | 
| Vault Namespace Admin | <ul><li>Add the Consumer Account in the `/auth/aws/sts/config` path</li><li>Add the Consumer Role ARN in the `/auth.aws/role` path and bind the vault role/policy</li></ul>| 

### 1.3.4 Sequence Diagram

![Image](/architecture/Vault_architecture-Option-1.svg)

### 1.3.5 Pros and Cons

| PROS | CONS | 
| --------------- | --------------- | 
| No Vault Account IAM Change Necessary | Uses wild card in policy |
| No Vault Account IAM Maintenance for Consumer ARNs | Consumer needs to add a custom vault policy to access vault secrets to every role.  |
 

## 1.4 Option 2

### 1.4.1 Overview
In this option, the focus is on strictest policies and no usage of wild cards. In this method as shown in the picture
below, the Vault assumes the instance profile and add the trusted roles that can access certain secret areas and associate
policies with them. However the vault doesn't need to do any change at an AWS account level. It is similar in architecture to Option 1.

The Vault EC2 Instance uses the following instance profile as shown below. As you can see with increasing number of consumers, the policy file size increase exponentially. There is a top limit to the size of the policy file, so thats the upper limit for support. This acts like a permission boundary in case, the vault configuration still allows a role to access certain secrets. This shouls only be used if there are difficulties changing the vault configuration too often. 

The target (consumer) account role has to explicitly trust the Vault account and needs to be use the exact role in order to
access vault secrets. AS


### 1.4.2 AWS Policies

- The Vault Instance Profile policy
```json5
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "<Your consumer account 1 arn>",
	    "Resource": "<Your consumer account 2 arn>",
	    "Resource": "<Your consumer account 3 arn>",
        }
    ]
}
```

- The Consumer Lambda Policy that is needed for vault access (unchanged from Option 1)
```yaml
- PolicyName: vault_policy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action: iam:GetRole
                Resource: !Sub 'arn:aws:iam::${AWS::AccountId}:role/HVaultOpt12FunctionRole'
              - Effect: Allow
                Action: sts:GetCallerIdentity
                Resource: '*'
```
- The Consumer Lambda Assume Policy Document (Trusting Vault) (unchanged from Option 1)
```yaml
AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - lambda.amazonaws.com
              AWS: !Sub
                - arn:aws:iam::${vaultaccountid}:root
                - { vaultaccountid: !Ref VaultAccountId}
            Action:
              - sts:AssumeRole
```


### 1.4.3 Roles & Responsibilities

| Roles | Responsibilities | 
| --------------- | --------------- | 
| Consumer| <ul><li>Attach the vault policy in the Lambda Execution Role</li><li>Add the relevant code to fetch secrets using the vault role (not AWS Role)</li><li>Trust the vault account</li></ul> | 
| Vault Namespace Admin | <ul><li>Add the Consumer Account in the `/auth/aws/sts/config` path</li><li>Add the Consumer Role ARN in the `/auth.aws/role` path and bind the vault role/policy</li></ul>| 
| Vault Instance Admin | Add the consumer role ARN in the Vault Instance Profile's policy in list of allowed resoruces|

### 1.4.4 Sequence Diagram

![Image](/architecture/Vault_architecture-Option-2.svg)

### 1.4.5 Pros and Cons

| PROS | CONS | 
| --------------- | --------------- | 
| Strictest Policies (No wild card usage) | Heavy maintenance of Vault instance profiles |
|  | Consumer needs to add a custom vault policy in all roles that need access to Vault  |

## 1.5 Option 3

### 1.5.1 Overview
In this option, the focus is on least effort on the consumer. In this method as shown in the picture
below, the Vault assumes the instance profile and allows access to roles belonging to the Vault AWS account only. Consumer need to assume the Vault AWS role in the Vault account and only then can access the secret. This passes over the control to Vault and as a consumer, all one needs to do is get the role arn to access. The drawback is that, once the role name is known, any program can use it as long as they can assume the role. Vault cannot singularly identify whether the secret was accessed by program A or program B.  

The Vault EC2 Instance uses the following instance profile as shown below. We shouldnt be using wild card here.

The target (consumer) account role has only allow the role to be abel to assume the Vault specified role arn in addition to the standard lambda policies.


### 1.5.2 AWS Policies

- The Vault Instance Profile policy
```json5
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "iam:GetRole",
            "Resource": "arn:aws:iam::<vault aws account id>:role/HVault*"
        }
    ]
}
```

- The Vault Instance Profile Trust Document (Trusting Consumers)
```yaml
AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              AWS: !Sub
                - arn:aws:iam::<consumer 1 account id>:root
                  arn:aws:iam::<consumer 1 account id>:root
            Action:
              - sts:AssumeRole
```

- The Consumer Lambda Policy does need to be able to trust the vault role as below
```json5
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "<Vault role ARN>"
        }
    ]
}
```

- The Consumer Lambda Assume Policy Document (Trusting Vault)



### 1.5.3 Roles & Responsibilities

| Roles | Responsibilities | 
| --------------- | --------------- | 
| Consumer| <ul><li>Assume the Vault AWS role</li><li>Add the relevant code to fetch secrets using the vault role (not AWS Role)</li></ul> | 
| Vault Namespace Admin | <ul><li>Add the Consumer Role ARN in the `/auth.aws/role` path and bind the vault role/policy</li></ul>| 
| Vault Instance Admin | Create the consumer IAM Role and trust the consumer account |

### 1.5.4 Sequence Diagram

![Image](/architecture/Vault_architecture-Option-3.svg)

### 1.5.5 Pros and Cons

| PROS | CONS | 
| --------------- | --------------- | 
| Least effort for consumer| Heavy maintenance for Vault Instance Admin for IAM in AWS Account |
|  | One wild card policy in the Vault Policy Admin |

## 1.6 Demo

The following example demonstrates a Lambda function using 3 different accounts for Option 1, 2 and 3. 

### 1.6.1 Steps & Prerequisites 
The following steps are done for a macOS 10.13 or later. Please do the equivalent installs if you need to replicate on 
Windows or Linux. It uses AWS CloudFormation for SAM to deploy the above architecture

**Prerequisites** 
The following method shows installation using HomeBrew. However, other tools like macports or direct
downloads can also be used. The following tools are needed
 - AWS CLI
 - AWS SAM CLI
 - Docker
 - Git
 - Postman or newman CLI for postman (for quick configuration of Vault)
```commandline
brew tap aws/tap
brew install docker aws-cli aws-sam-cli git
```

**Prepare your AWS account client configurations**

Add all 3 accounts with their respective profile ids - vault, namespace_1, namespace_2

```commandline
$ aws configure
AWS Access Key ID [None]: your_access_key_id
AWS Secret Access Key [None]: your_secret_access_key
Default region name [None]: 
Default output format [None]: 
```

**Checkout Git repo**
```commandline
git clone https://github.com/banroney/hvault-aws.git
```

### 1.6.1 Build,Package and Deploy - Deployment script 

You can install Vault 0.14 following the next steps. The command `hvault.sh` can run in 2 modes
1. -d: Deploy. This mode takes 5 options - `svc`, `auth`, `secret`,`config`, `all`. 
    a. `svc` - This option deploys an ECS powered Hashicorp Vault on AWS
    b. `auth` - This option deploys two consumers powered by Lambda and connects to an existing Hashicorp server. Running
    `all` automatically populates all values like Vaulr URL, token for the subsequent stages. 
    c. `secret` - This option deploys a Lambda powered secret sync which connects to an existing Hashicorp Vault. 
    d. `config` - This option runs a local script to configure Vault with some sample values demonstrating `auth` and 
    `secret`.
    
The generated configuration file will still need these values to be populated as mandatory or optional

```
#Mandatory - These are mandatory and needs to be populated for all stages
VAULT_SERVICE_AWS_ACCOUNTID=
VAULT_CLIENT_DOCKER_IMAGE_TAG=
VAULT_KMS_ADMIN_ARN=
VAULT_CERTIFICATE_ARN=
VAULT_VPC_ID=
VAULT_ECS_SUBNETS=
VAULT_ALB_SUBNETS=


#Optional - These are optional and if filled will progress to stage 2,3 and 4.
VAULT_ENTERPRISE_LICENSE_TEXT=

#Values for 2 consumers - Fill them up if you are deploying the Stage 2 as well
VAULT_CONSUMER_AWS_PROFILE_1=
VAULT_CONSUMER_AWS_ACCOUNT_ID_1=
VAULT_CONSUMER_NAMESPACE_1=

VAULT_CONSUMER_AWS_PROFILE_2=
VAULT_CONSUMER_AWS_ACCOUNT_ID_2=
VAULT_CONSUMER_NAMESPACE_2=

```

Example modes that `hvault.sh` can be run

Run all stages or deployments. 
```commandline
export PROJECT_ROOT=<your git cloned folder>
./hvault.sh -d all
```

Deploy Vault only 
```commandline
./hvault.sh -d svc
```

Deploy Authentication Module only
```commandline
./hvault.sh -d auth
```

Check deployment status for each stack
```commandline
./hvault.sh -s <aws-profile> <stack-name> <replacement values>
```
An example usage of the check status
```commandline
./hvault.sh -s default hvault-svc HVaultECSendpoint:VAULT_SERVICE_URL
```

### 1.6.2 Configure Vault
Deploy Config Module only
```commandline
./hvault.sh -d config
```


### 1.6.3 Testing and Verifying various options
Follow the steps to test the lambda functions in your AWS accounts

- Login to your AWS Consumer Account 1
- Switch to the Lambda Function
- Create 2 test events, one for Option 1 and 2 and another for Option 3. The contents of each of them should be as follows
  * Option 1/2
  ```json5
  {
    "queryStringParameters": {
      "vault_path": "opt12",
      "vault_role": "role_opt12",
      "assumed_role_arn": ""
    }
  }
  ```
  * Option 3
  ```json5
  {
    "queryStringParameters": {
      "vault_path": "opt12",
      "vault_role": "role_opt12",
      "assumed_role_arn": "your Option 3 Role ARN"
    }
  }
  ```
- Switch the Role of the Lambda function to HVaultOption12Role. Test the Lambda against test case Option12 should only work. Test against Option3 should fail
- Switch the Role of the Lambda function to HVaultOption3Role. Test the Lambda against test case Option3 should only work. Test against Option12 should fail
- Testing with any other combinations should fail.
- Note the failures and try to debug the cause of failure.
  


# 2. Hashicorp Vault Sync Secrets Manager


