
# **AWS Multi-Tier Architecture with Custom VPC**

## **Overview**
This project demonstrates how to build a custom VPC with multiple subnets, security groups, and EC2 instances to simulate a multi-tier architecture. It uses a Bastion host, web server, application server, and database instance with proper security group configurations.

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

## Prerequisites
- An [AWS account](https://aws.amazon.com/free/) (Free Tier eligible)

## **Step 1: VPC and Subnet Setup**
1. **Create a Custom VPC:**
   - **Name**: `MultiTierVPC`
   - **IPv4 CIDR Block**: `10.0.0.0/16`
   - **Tenancy**: Default

2. **Create Subnets:**
   - **Public Subnet** for the Bastion host and web server:
     - **Name**: `PublicSubnet`
     - **CIDR Block**: `10.0.1.0/24`
     - **Availability Zone**: `us-west-2a`
   
   - **Private Subnets** for the application server:
     - **Name**: `PrivateSubnetApp1`
     - **CIDR Block**: `10.0.2.0/24`
     - **Availability Zone**: `us-west-2a`
   
     - **Name**: `PrivateSubnetApp2`
     - **CIDR Block**: `10.0.3.0/24`
     - **Availability Zone**: `us-west-2b`
   
   - **Private Subnet** for the database:
     - **Name**: `PrivateSubnetDB`
     - **CIDR Block**: `10.0.4.0/24`
     - **Availability Zone**: `us-west-2b`
   
   ![chrome_n4gt5W9HHt](https://github.com/user-attachments/assets/cc25ff73-6d75-4773-b294-0463318fbaa6)





3. **Create an Internet Gateway (IGW):**
   - **Name**: `MultiTierIGW`
   - Attach it to the `MultiTierVPC`.

   ![chrome_tMXZYSTppm](https://github.com/user-attachments/assets/597800d8-5c96-4e50-8ffe-03d078a8a948)



4. **Create a NAT Gateway:**
   - Allocate an **Elastic IP Address**.
   - Create a NAT Gateway in the **PublicSubnet**.
   - **Name**: `MultiTierNATGateway`

   ![chrome_nWROEGvgUx](https://github.com/user-attachments/assets/aaf8899f-df1c-4d4d-be94-92e73c530f6b)


5. **Configure Route Tables:**
   - **Public Route Table**:
     - **Name**: `PublicRouteTable`
     - Associate with `PublicSubnet`.
     - Add route:
       - **Destination**: `0.0.0.0/0`
       - **Target**: `MultiTierIGW`

   ![chrome_qOfXjeubcD](https://github.com/user-attachments/assets/c403abcd-f7e7-4606-b152-511260227098)


   - **Private Route Table**:
     - **Name**: `PrivateRouteTable`
     - Associate with private subnets (`PrivateSubnetApp1`, `PrivateSubnetApp2`, `PrivateSubnetDB`).
     - Add route:
       - **Destination**: `0.0.0.0/0`
       - **Target**: `MultiTierNATGateway`

   ![chrome_mblkN1Ow1h](https://github.com/user-attachments/assets/f73326ea-8ab9-4a90-8d3c-17d373f009b3)

   ![chrome_ZdHj95HLlg](https://github.com/user-attachments/assets/11bb9840-e42c-4171-a130-7e1ed8d9de19)

   ![chrome_uY96DEJA7e](https://github.com/user-attachments/assets/e54c47ae-be0e-40f9-950a-c20a84de4389)




---

## **Step 2: Create Security Groups**
1. **Bastion Host Security Group**:
   - **Name**: `SG-Bastion`
   - **Rules**:
     - **Inbound**:
       - Type: SSH, Protocol: TCP, Port: 22, Source: `Your-Trusted-IP/32`
     - **Outbound**: Allow all traffic.

2. **Web Server Security Group**:
   - **Name**: `SG-WebServer`
   - **Rules**:
     - **Inbound**:
       - Type: HTTP, Protocol: TCP, Port: 80, Source: `0.0.0.0/0`
     - **Outbound**: Allow all traffic.

3. **Application Server Security Group**:
   - **Name**: `SG-AppServer`
   - **Rules**:
     - **Inbound**:
       - Type: MySQL/Aurora, Protocol: TCP, Port: 3306, Source: `SG-WebServer`
     - **Outbound**: Allow all traffic.

4. **Database Security Group**:
   - **Name**: `SG-Database`
   - **Rules**:
     - **Inbound**:
       - Type: MySQL/Aurora, Protocol: TCP, Port: 3306, Source: `SG-AppServer`
     - **Outbound**: Allow all traffic.

   ![chrome_TrPnucbZr5](https://github.com/user-attachments/assets/83fc6f28-5cb0-4da4-bcd1-77e9bbc63308)


---

## **Step 3: Deploy EC2 Instances**
### **Create Bastion Host**
1. **AMI**: Amazon Linux 2  
2. **Instance Type**: `t2.micro`  
3. **Subnet**: `PublicSubnet`  
4. **Security Group**: `SG-Bastion`  
5. **Key Pair**: Select or create a key pair  

**User Data (Optional)**:
```bash
#!/bin/bash
sudo yum update -y
```

### **Create Web Server**
1. **AMI**: Amazon Linux 2  
2. **Instance Type**: `t2.micro`  
3. **Subnet**: `PublicSubnet`  
4. **Security Group**: `SG-WebServer`  

**User Data**:
```bash
#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
```

### **Create App Server**
1. **AMI**: Amazon Linux 2  
2. **Instance Type**: `t2.micro`  
3. **Subnet**: `PrivateSubnetApp1`  
4. **Security Group**: `SG-AppServer`  

**User Data**:
```bash
#!/bin/bash
sudo yum install -y mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb
```

![chrome_Wqb1YFdmDs](https://github.com/user-attachments/assets/82d374a8-45b9-4bed-a0d6-65d5935b62ce)


---

## **Step 4: Configure RDS Database**
1. **Create a DB Subnet Group**:
   - **Name**: `DB-Subnet-Group`
   - **Subnets**: `PrivateSubnetDB`

2. **Launch RDS Instance**:
   - **Engine**: MariaDB  
   - **Instance Type**: `db.t2.micro`  
   - **VPC**: `MultiTierVPC`  
   - **Subnet Group**: `DB-Subnet-Group`  
   - **Public Access**: No  
   - **Security Group**: `SG-Database`  

**Credentials**:
- Username: `root`
- Password: `Re:Start!9`
- Initial Database: `mydb`

---

## **Step 5: Test Connectivity**
1. **Upload SSH Key to Bastion Host** and SSH into it.
2. **From Bastion Host**:
   - SSH into App Server using the `.pem` file:
   ```bash
   ssh -i labsuser.pem ec2-user@<app-server-private-ip>
   ```

3. **Verify Connectivity**:
   - **From App Server**: Test the database connection:
   ```bash
   mysql --user=root --password='Re:Start!9' --host=<RDS-endpoint>
   show databases;
   ```

---

## **Step 6: Clean Up Resources**
1. Terminate EC2 instances.
2. Delete the RDS instance.
3. Remove subnets, NAT Gateway, Internet Gateway, and VPC to avoid charges.
