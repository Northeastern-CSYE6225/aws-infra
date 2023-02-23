# aws-infra

CSYE 6225 Assignments
Karan Wadhwa
NUID: 002663034

## Quickstart

1. Install aws-cli and configure credentials

2. Initialize terraform

```console
$ terraform init
```

3. Create `.tfvars` file from `.example.tfvars` template
4. Plan your cloud infrastructure

```console
$ terraform plan -var-file <filename>.tfvars -var "profile=<aws-profile-name>"
```

5. Create your cloud infrastructure

```console
$ terraform apply -var-file <filename>.tfvars -var "profile=<aws-profile-name>"
```

6. Destroy your cloud infrastructure

```console
$ terraform apply -var-file <filename>.tfvars -var "profile=<aws-profile-name>"
```
