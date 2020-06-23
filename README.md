# Hashicorp Vault AWS Integration
 Hashicorp AWS Integration Scenarios
 
 The following options are the listed scenarios: 
 
 
## Overall Architecture

![Image](/architecture/AWS-vault.jpg)

## Option 1

![Image](/architecture/Vault_architecture-Option-1.jpg)

## Option 2

![Image](/architecture/Vault_architecture-Option-2.jpg)

## Option 3

![Image](/architecture/Vault_architecture-Option-3.jpg)


## Demo

The following example demonstrates a Lambda function using 3 different accounts for Option 1, 2 and 3. 

### Prequisites 
The following steps are done for a macOS 10.13 or later. Please do the equivalent installs if you need to replicate on 
Windows or Linux.


1. Install Ruby, Brew, AWS-CLI, Git, Docker and AWS-SAM-CLI

```commandline
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)”
brew tap aws/tap
brew install docker aws-cli aws-sam-cli git
```

### Steps to follow to implement reference function

2. Prepare your AWS account config info, add all 3 accounts with their respective profile ids - vault, namespace_1, namespace_2

```commandline
$ aws configure
AWS Access Key ID [None]: your_access_key_id
AWS Secret Access Key [None]: your_secret_access_key
Default region name [None]: 
Default output format [None]: 
```


3. Checkout Git repo
```commandline
git clone https://github.com/banroney/hvault-aws.git
```

**Do Steps 4, 5, 6 for 2 AWS accounts -** 

4. Build SAM
Replace `project_folder` with the location of the git checked-out folder

```commandline
cd <project_folder> && \
sam build \
    —-profile <AWS_Account_Profile>
    --template template.yaml \
    --build-dir .aws-sam/build \
    --use-container
```


5. Package SAM 
Provide your S3 bucket name that can be used to upload the built SAM package
 - Replace `<project_folder>` with the location of the git checked-out folder
 - Replace `<S3_bucket_Name>` wih the name of the bucket in the target profile to upload
 the built package to

```commandline
cd <project_folder> && \
sam package \
    —-profile <AWS_Account_Profile>
    --template-file .aws-sam/build/template.yaml \
    --output-template-file .aws-sam/build/packaged-template.yaml \
    --s3-bucket <S3_bucket_Name>
```


6. Deploy SAM
In the `parameter-overrides` section, please provide the details as mentioned below. 
This refers to the values of your server. Replace the following before running the command
 - 

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

