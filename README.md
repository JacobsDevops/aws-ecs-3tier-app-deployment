Description
This repository contains a CI/CD pipeline for deploying a 3-tier application on AWS ECS (Fargate) using Terraform, GitHub Actions, and Docker. 
The application consists of:

Frontend: React
Backend: NodeJS
Database: PostgreSQL 

Key Features
✅ Infrastructure as Code (IaC) with Terraform for automated provisioning.
✅ GitHub Actions CI/CD for automated builds and deployments.
✅ AWS ECS (Fargate) deployment for containerized services.
✅ Secure environment with IAM roles, security groups, and networking setup.


Tech Stack
Terraform for infrastructure automation
GitHub Actions for CI/CD
AWS ECS (Fargate) for container orchestration
AWS ECR for container registry
PostgreSQL (AWS RDS or ECS) for database
Docker for containerized application
Flask (Backend API) & React (Frontend UI)

Deployment Flow
1️⃣ Code Changes: Pushed to GitHub → Triggers CI/CD pipeline
2️⃣ Build & Push: Docker images are built & pushed to AWS ECR
3️⃣ Terraform Apply: Deploys infrastructure (ECS, networking, security)
4️⃣ ECS Update: New task definitions & services are deployed