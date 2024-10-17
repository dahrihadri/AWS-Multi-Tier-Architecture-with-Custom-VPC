
# **AWS Multi-Tier Architecture with Custom VPC**

## **Overview**
In this project, I’ll walk you through creating a custom Virtual Private Cloud (VPC) in AWS to simulate a multi-tier architecture. This setup is a great way to understand how a layered environment works, much like real-world applications in production environments. We’ll use a Bastion host, web server, application server, and database server while ensuring each has the appropriate security group configurations for secure communication.

This is a practical project for those wanting to explore cloud architecture and how AWS services interconnect while maintaining network isolation and security.

![chrome_eoAELUeYMe](https://github.com/user-attachments/assets/3076e948-9f7e-470d-9f67-e39e818e7b28)

---

## **Table of Contents**
- [Prerequisites](#prerequisites)
- [Step 1: VPC and Subnet Setup](#step-1-vpc-and-subnet-setup)
- [Step 2: Create Security Groups](#step-2-create-security-groups)
- [Step 3: Deploy EC2 Instances](#step-3-deploy-ec2-instances)
- [Step 4: Configure RDS Database](#step-4-configure-rds-database)
- [Step 5: Test Connectivity](#step-5-test-connectivity)
- [Step 6: Clean Up Resources](#step-6-clean-up-resources)

---

## **Prerequisites**
Before we dive in, make sure you have:
- An [AWS account](https://aws.amazon.com/free/) (Free Tier eligible)
- Basic knowledge of EC2, VPCs, and RDS, although I’ll explain things as we go. 

AWS Free Tier will allow you to explore without upfront cost, but always keep an eye on your resources to avoid unnecessary charges.

---

## **Step 1: VPC and Subnet Setup**
### **1.1 Create a Custom VPC**
We start by creating a VPC to simulate our isolated environment. Think of the VPC as a dedicated network within AWS where we have control over IP addressing, subnets, routing, and gateways.

- **VPC Name**: `MultiTierVPC`
- **IPv4 CIDR Block**: `192.168.0.0/16`
- **Tenancy**: Default (unless you’re working with Dedicated Instances, stick to default)

By using `192.168.0.0/16`, we get a large address space that’s flexible enough to divide into several subnets later.

---

### **1.2 Create Subnets**
Subnets allow us to organize and isolate parts of our VPC into logical zones (availability zones in AWS). The key here is to divide the network into public and private subnets:

- **Public Subnet**: This is where our Bastion host and web server will live.
  - **Name**: `PublicSubnet`
  - **CIDR Block**: `192.168.1.0/24`
  - **Availability Zone**: `us-west-2a`

- **Private Subnets**: Used for application servers and databases, where they won't be accessible directly from the internet for security reasons.
  - **PrivateSubnet1**: For the application server (`192.168.2.0/24`)
  - **PrivateSubnet2**: Another application subnet (`192.168.3.0/24`)
  - **PrivateSubnet3**: Reserved for the database (`192.168.4.0/24`)

Each subnet will be isolated to ensure we can apply specific security rules later.

---
   
### **1.3 Internet Gateway (IGW)**
An **Internet Gateway** connects our VPC to the outside world, allowing our public instances to communicate with the internet.

- **Name**: `MultiTierIGW`
- Attach it to `MultiTierVPC`.

   ![chrome_tMXZYSTppm](https://github.com/user-attachments/assets/597800d8-5c96-4e50-8ffe-03d078a8a948)



---

### **1.4 NAT Gateway**
The **NAT Gateway** is essential for allowing instances in private subnets to initiate outbound connections to the internet (for updates, package installs, etc.) without exposing them to inbound traffic.

- Allocate an **Elastic IP** and set up the NAT Gateway in the **PublicSubnet**.
- **Name**: `MultiTierNATGateway`.

   ![chrome_nWROEGvgUx](https://github.com/user-attachments/assets/aaf8899f-df1c-4d4d-be94-92e73c530f6b)

---

### **1.5 Route Tables**
Route tables control the flow of traffic in and out of subnets. Here, we’ll configure two types of route tables:

- **Public Route Table**: Directs traffic to the internet via the IGW.
  - **Destination**: `0.0.0.0/0` (this routes all traffic to the internet)
  - **Target**: `MultiTierIGW`

   ![chrome_uB8TCdcVHV](https://github.com/user-attachments/assets/441a14f1-cd0a-47a0-8033-234d86fca992)

   ![chrome_CoXy2HVVtC](https://github.com/user-attachments/assets/b7af003e-ca00-433c-b90b-3e3b0a293dc9)

- **Private Route Table**: Routes private subnet traffic through the NAT Gateway to access the internet for outbound requests (e.g., app updates).
  - **Target**: `MultiTierNATGateway`

This setup ensures that while the private subnets can access the internet, they won’t be accessible from outside, enhancing security.

   ![chrome_fnbeMGjJsY](https://github.com/user-attachments/assets/934b6975-9054-4d88-85fa-cfbb1edb425b)

   ![chrome_JirlJxGh0X](https://github.com/user-attachments/assets/1d8dcb8f-4061-4fb2-9d3d-c50eda7294de)

   ![chrome_ufT9Iiyh5C](https://github.com/user-attachments/assets/e617db27-917d-40ba-b74f-d07fb93fb973)

---
## **Step 2: Create Security Groups**
Security groups act as virtual firewalls, controlling traffic at the instance level. Here’s how we’ll configure them:

### **2.1 Bastion Host Security Group**
The Bastion host serves as an entry point for administrators. Only trusted IP addresses should be allowed to SSH into it.

- **Inbound Rules**:
  - SSH from your IP (`Your-Trusted-IP/32`)
- **Outbound Rules**: Allow all traffic.

This limits who can access your infrastructure and ensures the Bastion host remains secure.

   ![chrome_JfFLU8ywxq](https://github.com/user-attachments/assets/77dc2811-939d-4953-a798-2f68baef6522)

---

### **2.2 Web Server Security Group**
The web server is accessible via HTTP and HTTPS. However, we will still keep security tight.

- **Inbound Rules**:
  - HTTP (Port 80) from anywhere (`0.0.0.0/0`)
  - HTTPS (Port 443) from anywhere
- **Outbound Rules**: Allow all traffic.

   ![chrome_U0V6PXqW4m](https://github.com/user-attachments/assets/90eb79a6-d126-42ce-979d-3fbefb7b114d)

---

### **2.3 Application Server Security Group**
For the application server, we want it to communicate only with the web server and the database.

- **Inbound Rules**:
  - MySQL (Port 3306) from the Web Server Security Group
  - SSH access from the Bastion host.
    
   ![chrome_QjgOq7rgYW](https://github.com/user-attachments/assets/fee42064-8a93-4cec-8d02-fbf340fbf3ca)

---

### **2.4 Database Security Group**
The database will accept traffic only from the application server.

- **Inbound Rules**:
  - MySQL (Port 3306) from the App Server Security Group.

This way, the database is isolated and only accessible by authorized components.
    
   ![chrome_ojIvDlsM96](https://github.com/user-attachments/assets/0ab6372b-1b5f-4b8a-a6f3-44c3ed0f5841)

   ![chrome_DefONrJXMG](https://github.com/user-attachments/assets/1d81740e-0a42-450a-ac8b-29c65515c393)

---

## **Step 3: Deploy EC2 Instances**
We’ll now deploy the Bastion host, web server, and application server.

### **Bastion Host**:
- **AMI**: Amazon Linux 2  
- **Instance Type**: `t2.micro`  
- **Security Group**: `SG-Bastion`  
- **Auto-assign Public IP**: Yes  

**User Data** (to update and prepare the instance):
```bash
#!/bin/bash
sudo yum update -y
```

### **Web Server**:
Similar to the Bastion host, but it runs an HTTP server.

**User Data**:
```bash
#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
```

The web server will be reachable from the internet.

---

### **Application Server**:
This sits in the private subnet, running behind the web server.

**User Data**:
```bash
#!/bin/bash
sudo yum install -y mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb
```

This application server will connect to the database and handle backend processes.

![chrome_Wqb1YFdmDs](https://github.com/user-attachments/assets/82d374a8-45b9-4bed-a0d6-65d5935b62ce)

---

## **Step 4: Configure RDS Database**
The final component is setting up an RDS instance in the private subnet.

### **4.1 Create a DB Subnet Group:**
   - **Name**: `DB-Subnet-Group`
   - **Subnets**: `PrivateSubnetDB`

![chrome_MfLu2pnuaR](https://github.com/user-attachments/assets/6f2b4cb9-4231-4fed-aa42-0d3ce7df0c5e)

### **4.2 Launch RDS Instance:**
   - **Engine**: MariaDB  
   - **Instance Type**: `db.t2.micro` or `db.t4g.micro` 
   - **VPC**: `MultiTierVPC`  
   - **Subnet Group**: `DB-Subnet-Group`  
   - **Public Access**: No  
   - **Security Group**: `SG-Database`  

**Credentials**:
- Username: `root`
- Password: `Re:Start!9`
- Initial Database: `mydb`

This instance won’t be directly accessible from the internet, only via the app server.

![chrome_hMUt4lCPil](https://github.com/user-attachments/assets/2210c67c-d3fe-4d3d-8f58-3e6c58a2c0ad)

---

## **Step 5: Test Connectivity**
Here, we verify connectivity by SSHing into the Bastion host, then into the app server, and finally checking the database connection.

### **5.1 Upload SSH Key to Bastion Host** and SSH into it.

```bash
scp -i "C:\path\to\your\key.pem" -P 22 "C:\path\to\your\key.pem" ec2-user@your-ec2-public-ip:/home/ec2-user/
```

![chrome_EhSdfA076V](https://github.com/user-attachments/assets/26b6a99b-faf8-41a1-af4e-3b8b8fa6af4e)

![chrome_mWeULAx4qP](https://github.com/user-attachments/assets/910bb466-fd7a-4a08-8b30-ebb5c7f8c652)

### **5.2 From Bastion Host**:
   - SSH into App Server using the `.pem` file:
   ```bash
   ssh -i labsuser.pem ec2-user@<app-server-private-ip>
   ```
![chrome_nXW0eDA46u](https://github.com/user-attachments/assets/5631d0a6-04b4-456f-bd37-280146502bf3)

### **5.3 Verify Connectivity**:
   - **From App Server**: Test the database connection:
   ```bash
   mysql --user=root --password='Re:Start!9' --host=<RDS-endpoint>
   show databases;
   ```
![chrome_2lds3nWztC](https://github.com/user-attachments/assets/3164c8f7-a95c-4622-a57e-5e5f9a4ef204)

---

## **Step 6: Clean Up Resources**
Always clean up after yourself to avoid AWS charges. Terminate EC2 instances, delete RDS, and remove any associated AWS resources (like the VPC, subnets, etc.).

