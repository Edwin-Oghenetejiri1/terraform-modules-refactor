# 🏗️ Terraform Refactor: Monolith to Modules

> Refactoring infrastructure-as-code from a single `main.tf` file into a clean, reusable module architecture on AWS — without recreating a single resource.

---

## 📌 Project Overview

This project demonstrates a real-world Terraform refactoring workflow. Starting from a monolithic configuration, the infrastructure is reorganized into **three reusable modules** (`vpc`, `compute`, `database`) while keeping the AWS environment completely intact.

The key engineering challenge: **migrate Terraform state** to reflect the new module paths — so no resources are destroyed or recreated during the refactor.

---

## ☁️ AWS Infrastructure Provisioned

| Resource | Details |
|---|---|
| **VPC** | Custom VPC with DNS support enabled |
| **Subnets** | 2 public subnets across `us-east-1a` and `us-east-1b` |
| **Internet Gateway** | Attached to VPC for public internet access |
| **Route Table** | Public route table with associations to both subnets |
| **Security Group** | Controls inbound/outbound traffic for EC2 |
| **EC2 Instance** | Web server launched in public subnet |
| **RDS Instance** | Relational database in a dedicated subnet group |
| **S3 + DynamoDB** | Remote backend for state storage and state locking |

---

## 🗂️ Project Structure

```
terraform-modules-refactor/
├── monolithic/
│   └── main.tf                     # Original single-file config (starting point)
│
├── modules/
│   ├── vpc/
│   │   ├── main.tf                 # VPC, Subnets, IGW, Route Table
│   │   ├── variables.tf            # CIDR blocks, availability zones
│   │   └── outputs.tf              # vpc_id, public_subnet_ids
│   │
│   ├── compute/
│   │   ├── main.tf                 # Security Group, EC2 Instance
│   │   ├── variables.tf            # vpc_id, subnet_id
│   │   └── outputs.tf              # instance_public_ip
│   │
│   └── database/
│       ├── main.tf                 # DB Subnet Group, RDS Instance
│       ├── variables.tf            # subnet_ids, db credentials
│       └── outputs.tf              # db_endpoint
│
├── main.tf                         # Root config — wires modules together
└── README.md
```

---

## 🔄 Before vs After

The `monolithic/` folder preserves the original starting point of this project — all infrastructure defined in a single `main.tf` file. This is common when first learning Terraform but doesn't scale in real teams.

| | Monolithic (`monolithic/main.tf`) | Modular (`main.tf` + `modules/`) |
|---|---|---|
| **Structure** | Everything in one file | Split across focused modules |
| **Reusability** | None — hardcoded values | Variables make it reusable across envs |
| **Readability** | Hard to navigate as it grows | Each module has a single responsibility |
| **Collaboration** | Merge conflicts likely | Teams can work on modules independently |
| **Real-world use** | Learning / prototyping | Production standard |

The infrastructure provisioned in AWS is **identical** in both versions. The refactor is purely an improvement in code organization.

---

## ⚙️ Module Architecture

```
root main.tf
    │
    ├── module "network"
    │       └── outputs: vpc_id, public_subnet_ids
    │
    ├── module "compute"
    │       ├── inputs:  vpc_id ← network.vpc_id
    │       │            subnet_id ← network.public_subnet_ids[0]
    │       └── outputs: instance_public_ip
    │
    └── module "database"
            ├── inputs:  subnet_ids ← network.public_subnet_ids
            │            db_name, db_username, db_password
            └── outputs: db_endpoint
```

The root `main.tf` acts purely as a **wiring layer** — it passes outputs from one module as inputs to another. No resource logic lives here.

---

## 🔁 The State Migration

The most critical part of this refactor was **migrating the Terraform state** to match the new module paths. Without this step, Terraform would plan to destroy and recreate every resource.

After moving code into modules, `terraform plan` initially showed resources as needing replacement. The fix was `terraform state mv`:

```bash
# Network resources
terraform state mv aws_vpc.main                              module.vpc.aws_vpc.this
terraform state mv aws_subnet.public                         module.vpc.aws_subnet.public_1
terraform state mv aws_subnet.public_2                       module.vpc.aws_subnet.public_2
terraform state mv aws_internet_gateway.igw                  module.vpc.aws_internet_gateway.igw
terraform state mv aws_route_table.public_rt                 module.vpc.aws_route_table.public_rt
terraform state mv aws_route_table_association.public_assoc_1 module.vpc.aws_route_table_association.public_assoc_1
terraform state mv aws_route_table_association.public_assoc_2 module.vpc.aws_route_table_association.public_assoc_2

# Compute resources
terraform state mv aws_security_group.web_sg                 module.compute.aws_security_group.web_sg
terraform state mv aws_instance.web                          module.compute.aws_instance.web

# Database resources
terraform state mv aws_db_subnet_group.db_subnet_group       module.database.aws_db_subnet_group.db_subnet_group
terraform state mv aws_db_instance.db                        module.database.aws_db_instance.db
```

After migration, `terraform plan` confirmed:

```
No changes. Infrastructure is up-to-date.
```

✅ Zero resources destroyed. Zero resources recreated.

---

## 🚀 How to Use This Project

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- AWS CLI configured with appropriate credentials
- An S3 bucket and DynamoDB table for remote state (or update `main.tf` to use local state)

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/<your-username>/terraform-modules-refactor.git
cd terraform-modules-refactor

# 2. Initialize Terraform (downloads providers and loads modules)
terraform init

# 3. Preview the execution plan
terraform plan

# 4. Apply the configuration
terraform apply
```

> ⚠️ This project provisions real AWS resources. Costs may apply. Run `terraform destroy` when done.

---

## 💡 Key Concepts Demonstrated

| Concept | Description |
|---|---|
| **Module encapsulation** | Each module owns its resources and exposes only what other modules need |
| **Input variables** | Hardcoded values replaced with `var.*` for reusability across environments |
| **Module outputs** | Modules share data via outputs rather than direct resource references |
| **`terraform state mv`** | Migrates state entries to match refactored paths — no infrastructure changes |
| **Remote backend** | State stored in S3 with DynamoDB locking for team safety |
| **`terraform init` after refactor** | Required whenever module structure changes |

---

## 📚 What I Learned

- How Terraform tracks resources via **state**, not file location — this is why moving code alone isn't enough
- The importance of running `terraform plan` before `apply` and reading it carefully
- How `terraform state mv` safely bridges the gap between old and new resource paths
- How modules communicate using **inputs and outputs** rather than direct references
- Why the root `main.tf` should be a clean **orchestration layer**, not a resource dump

---

## 🧹 Cleanup

```bash
terraform destroy
```

This will remove all AWS resources provisioned by this project.

---

## 📄 License

MIT