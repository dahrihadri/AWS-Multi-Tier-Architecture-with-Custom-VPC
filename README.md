
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
   - **IPv4 CIDR Block**: `192.168.0.0/16 `
   - **Tenancy**: Default

2. **Create Subnets:**
   - **Public Subnet** for the Bastion host and web server:
     - **Name**: `PublicSubnet`
     - **CIDR Block**: `192.168.1.0/24`
     - **Availability Zone**: `us-west-2a`
   
   - **Private Subnets** for the application server:
     - **Name**: `PrivateSubnet1`
     - **CIDR Block**: `192.168.2.0/24`
     - **Availability Zone**: `us-west-2a`
   
     - **Name**: `PrivateSubnet2`
     - **CIDR Block**: `192.168.3.0/24`
     - **Availability Zone**: `us-west-2a`
   
   - **Private Subnet** for the database:
     - **Name**: `PrivateSubnet3`
     - **CIDR Block**: `192.168.4.0/24`
     - **Availability Zone**: `us-west-2b`
   
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

   ![chrome_uB8TCdcVHV](https://github.com/user-attachments/assets/441a14f1-cd0a-47a0-8033-234d86fca992)

   ![chrome_CoXy2HVVtC](https://github.com/user-attachments/assets/b7af003e-ca00-433c-b90b-3e3b0a293dc9)


   - **Private Route Table**:
     - **Name**: `PrivateRouteTable`
     - Associate with private subnets (`PrivateSubnetApp1`, `PrivateSubnetApp2`, `PrivateSubnetDB`).
     - Add route:
       - **Destination**: `0.0.0.0/0`
       - **Target**: `MultiTierNATGateway`

   ![chrome_fnbeMGjJsY](https://github.com/user-attachments/assets/934b6975-9054-4d88-85fa-cfbb1edb425b)

   ![chrome_JirlJxGh0X](https://github.com/user-attachments/assets/1d8dcb8f-4061-4fb2-9d3d-c50eda7294de)

   ![chrome_ufT9Iiyh5C](https://github.com/user-attachments/assets/e617db27-917d-40ba-b74f-d07fb93fb973)

---

## **Step 2: Create Security Groups**
1. **Bastion Host Security Group**:
   - **Name**: `SG-Bastion`
   - **Rules**:
     - **Inbound**:
       - Type: SSH, Protocol: TCP, Port: 22, Source: `Your-Trusted-IP/32`. Give it three inbound rules, one for SSH using your IP and one for HTTP using 0.0.0.0/0 as well as https using 0.0.0.0/0
     - **Outbound**: Allow all traffic.

   ![chrome_JfFLU8ywxq](https://github.com/user-attachments/assets/77dc2811-939d-4953-a798-2f68baef6522)


2. **Web Server Security Group**:
   - **Name**: `SG-WebServer`
   - **Rules**:
     - **Inbound**:
       - Type: HTTP, Protocol: TCP, Port: 80, Source: `0.0.0.0/0`. Give it the same inbound rules as the Bastion Host security group
     - **Outbound**: Allow all traffic.

   ![chrome_U0V6PXqW4m](https://github.com/user-attachments/assets/90eb79a6-d126-42ce-979d-3fbefb7b114d)


3. **Application Server Security Group**:
   - **Name**: `SG-AppServer`
   - **Rules**:
     - **Inbound**:
       - Type: MySQL/Aurora, Protocol: TCP, Port: 3306, Source: `SG-WebServer`. Give it an inbound rule for All ICMP -IPv4 with a source of your web server SG and another inbound rule for SSH with a source of your bastion host SG
     - **Outbound**: Allow all traffic.
    
   ![chrome_QjgOq7rgYW](https://github.com/user-attachments/assets/fee42064-8a93-4cec-8d02-fbf340fbf3ca)


4. **Database Security Group**:
   - **Name**: `SG-Database`
   - **Rules**:
     - **Inbound**:
       - Type: MySQL/Aurora, Protocol: TCP, Port: 3306, Source: `SG-AppServer`. Give it two inbound rules both for MYSQL/Aurora and give one of them a source of your app server SG and the other one a source of your bastion host SG
     - **Outbound**: Allow all traffic.
    
   ![chrome_ojIvDlsM96](https://github.com/user-attachments/assets/0ab6372b-1b5f-4b8a-a6f3-44c3ed0f5841)

   ![chrome_DefONrJXMG](https://github.com/user-attachments/assets/1d81740e-0a42-450a-ac8b-29c65515c393)

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

![chrome_MfLu2pnuaR](https://github.com/user-attachments/assets/6f2b4cb9-4231-4fed-aa42-0d3ce7df0c5e)

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
