# Serverless Financial Fraud Detection Platform (AWS Cloud Architecture)

An enterprise serverless architecture designed to process financial fraud detection pipelines at scale. The platform decouples computation into event-driven AWS services, presenting telemetry via an interactive single-page dashboard.

---

## Architecture Overview

```text
+-----------------------+       HTTPS GET        +------------------------+
|   Browser Frontend    | ---------------------> |   Amazon API Gateway   |
| (S3 Static Hosting)   |                        |       (HTTP API)       |
+-----------------------+                        +------------------------+
                                                             |
                                                             | Proxy Integration
                                                             v
+-----------------------+       PutObject        +------------------------+
|       Amazon S3       | <--------------------- |    AWS Lambda Function |
|  (Artifact Storage)   |                        |      (Python 3.12)     |
+-----------------------+                        +------------------------+



Client Tier: Static HTML5, Chart.js, and CSS single-page interface deployed to Amazon S3 (Static Website Hosting).

Ingress Tier: Amazon API Gateway HTTP API providing low-latency routing and CORS preflight negotiation.

Compute Tier: AWS Lambda (ap-southeast-2) executing simulated continuous transaction ingestion, feature computation, and triage scoring.

Storage Tier: Amazon S3 bucket retaining pipeline evaluation artifacts, EDA rollups, and operational audit logs.