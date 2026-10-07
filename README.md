# Serverless Real-Time Financial Fraud Detection Platform

An enterprise-grade, event-driven serverless system for financial transaction surveillance and fraud triage. This architecture executes continuous data validation, exploratory behavioral metrics, feature computation, and machine learning scoring on AWS infrastructure without persistent server overhead.

---

## Architectural Topology

The system uses a decoupled cloud architecture designed for high availability, zero idle operational cost, and low-latency client telemetry:

```text
+-------------------------------------------------------------------------------+
|                             Client Layer (AWS S3)                             |
|                                                                               |
|   Static Single Page Application (HTML5 / Vanilla JavaScript / Chart.js)      |
|   - Hosted via Amazon S3 Static Website Hosting                               |
|   - Performs asynchronous polling and interactive visual audits               |
+---------------------------------------+---------------------------------------+
                                        |
                             HTTPS / JSON REST Calls
                                        |
+---------------------------------------v---------------------------------------+
|                             Ingress (API Gateway)                             |
|                                                                               |
|   Amazon API Gateway (HTTP API v2)                                            |
|   - Regional Endpoint: ap-southeast-2 (Sydney)                                |
|   - Native CORS Preflight Handling (OPTIONS, GET)                             |
|   - Payload Proxy Integration                                                 |
+---------------------------------------+---------------------------------------+
                                        |
                            Lambda Proxy Integration
                                        |
+---------------------------------------v---------------------------------------+
|                            Compute (AWS Lambda)                               |
|                                                                               |
|   AWS Lambda Execution Environment                                            |
|   - Runtime: Python 3.12 (Pure Python execution profile)                      |
|   - Pipeline Execution Engine (Stages 1 through 7 Orchestration)               |
|   - IAM Execution Role: S3 Object Ingestion & CloudWatch Log Stream           |
+---------------------------------------+---------------------------------------+
                                        |
                            boto3 PutObject (JSON Payloads)
                                        |
+---------------------------------------v---------------------------------------+
|                            Storage (Amazon S3)                                |
|                                                                               |
|   Amazon S3 Artifact Storage (`fraud-detection-data-anish-syd`)               |
|   - /artifacts/eda_summary.json                                               |
|   - /artifacts/model_metrics.json                                             |
|   - /artifacts/latest_summary.json                                            |
|   - /pipeline_status.json                                                     |
+-------------------------------------------------------------------------------+
```

---

## Technical Specifications

### Infrastructure Components

* **Cloud Region:** Asia Pacific Sydney (`ap-southeast-2`)
* **Compute Engine:** AWS Lambda (2048 MB memory profile, sub-500ms execution latency)
* **API Protocol:** Amazon API Gateway HTTP API with low-latency regional route mappings
* **Frontend Delivery:** Amazon S3 Static Website Hosting with cross-origin client isolation
* **Data Storage:** Amazon Simple Storage Service (S3) for operational audit states and summary telemetry
* **Visualization Layer:** Responsive Chart.js canvas elements rendered inside a zero-dependency DOM

### Model Validation and Operational Triage Strategy

Traditional machine learning classifiers evaluate against fixed default cutoffs (p >= 0.5). In high-throughput banking systems, this generates review volumes that exceed human capacity. This pipeline implements operational capacity routing:

| Triage Tier | Score Threshold | Allocated Capacity | Operational Workflow |
| :--- | :--- | :--- | :--- |
| **Automatic Block** | p >= 0.824 | Approximately 3.5% | Transaction canceled immediately; origin account flagged for restriction |
| **SOC Review Queue** | 0.412 <= p < 0.824 | Approximately 5.5% | Routed to human fraud investigators for secondary manual audit |
| **Direct Approve** | p < 0.412 | Approximately 91.0% | Cleared for immediate settlement and ledger balance deduction |

---

## Pipeline Execution Stages

The core execution engine processes transaction data across seven deterministic stages:

1. **Stage 1: Continuous Ingestion Engine**  
   Simulates transaction batch creation across primary payment channels (`PAYMENT`, `TRANSFER`, `CASH_OUT`, `DEBIT`, `CASH_IN`) with synthetic volume scaling.
2. **Stage 2: Data Cleaning and Integrity Audit**  
   Validates balance continuity, sanitizes empty fields, and filters invalid synthetic records.
3. **Stage 3: Exploratory Behavioral Profiling**  
   Aggregates baseline statistics, mean velocity figures, channel-specific distributions, and confirms baseline fraud rates.
4. **Stage 4: Leak-Free Feature Engineering**  
   Calculates temporal indicators, origin account transaction frequency, destination velocity limits, and ledger delta balances without forward-looking data leakage.
5. **Stage 5: Chronological Partitioning**  
   Enforces strict temporal step boundaries (75% training partition, 25% out-of-time evaluation partition) to prevent data snooping.
6. **Stage 6: Model Evaluation and Parity Verification**  
   Calculates precision-recall metrics (PR-AUC) and receiver operating characteristic curves (ROC-AUC) against historical validation splits.
7. **Stage 7: Operational Triage and Decision Routing**  
   Applies dynamic thresholds to classify audited transactions into Block, Review, and Approve pipelines.

---

## Repository Structure

```text
aws-financial-fraud-detection/
├── .gitignore                      # Git exclusion rules for Python caches and environment files
├── README.md                       # Comprehensive platform documentation
├── backend/
│   ├── lambda_function.py          # Serverless handler, pipeline logic, and S3 artifact sync
│   └── requirements.txt            # Dependency definitions for AWS Lambda execution
├── frontend/
│   ├── index.html                  # Multi-stage interactive dashboard and telemetry UI
│   └── assets/
│       └── logo.png                # Platform icon and visual branding assets
└── deploy/
    └── deploy_s3.sh                # Shell script for automated frontend S3 deployment
```

---

## API Reference

### Health and Pipeline Execution Trigger

* **Method:** `GET`
* **Route:** `/pipeline`
* **Headers:** `Accept: application/json`

#### Response Body Schema (`HTTP 200 OK`)

```json
{
  "message": "Success",
  "summary": {
    "total_audited": 50000,
    "confirmed_fraud": 1803
  },
  "eda_summary": {
    "total_audited": 50000,
    "confirmed_fraud": 1803,
    "fraud_rate_pct": 3.61,
    "average_amount": 249694.58
  },
  "triage_summary": {
    "total_scored": 50000,
    "approve_count": 45500,
    "review_count": 2750,
    "block_count": 1750
  }
}
```

#### Preflight CORS Response (`OPTIONS`)

* **Status:** `200 OK`
* **Response Headers:**
  * `Access-Control-Allow-Origin: *`
  * `Access-Control-Allow-Methods: GET, POST, OPTIONS`
  * `Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept`

---

## Deployment Guide

### Prerequisites

* AWS CLI installed and configured with appropriate administrative credentials.
* Amazon S3 bucket for pipeline artifact storage (`fraud-detection-data-anish`).
* Amazon S3 bucket for frontend website hosting.

### 1. Backend Provisioning

1. Open the AWS Lambda console in region `ap-southeast-2`.
2. Create a function named `FraudPipelineRunner` using the `Python 3.12` runtime.
3. Assign an IAM role with the following baseline permissions:
   * `AWSLambdaBasicExecutionRole` (CloudWatch Logging)
   * Inline policy granting `s3:PutObject` on `arn:aws:s3:::fraud-detection-data-anish/*`
4. Copy `backend/lambda_function.py` into the Lambda editor and deploy.
5. In **Configuration > Environment variables**, add:
   * Key: `DATA_BUCKET_NAME`
   * Value: `fraud-detection-data-anish-syd`

### 2. API Gateway Configuration

1. In the Amazon API Gateway console, provision an **HTTP API**.
2. Create an integration targeting the `FraudPipelineRunner` Lambda function.
3. Configure route: `GET /pipeline`.
4. Enable the `$default` stage with automatic deployment enabled.
5. In **CORS Configuration**, specify:
   * Allowed Origins: `*`
   * Allowed Methods: `GET`, `OPTIONS`
   * Allowed Headers: `Content-Type`, `Authorization`, `X-Requested-With`, `Accept`

### 3. Frontend Deployment

1. Open `frontend/index.html` in an editor.
2. Locate `API_URL` and update the value to your live API Gateway endpoint:
   ```javascript
   const API_URL = "Hidden for security purpose";
   ```
3. Deploy the application assets using the provided shell script:
   ```bash
   chmod +x deploy/deploy_s3.sh
   ./deploy/deploy_s3.sh
   ```
4. Access the web dashboard via the generated S3 Static Website Hosting endpoint.

---

## Security and Operational Integrity

* **Zero Lookahead Bias:** Feature stores and historical windows prevent the inclusion of transaction records with step indices >= t.
* **Stateless Compute:** AWS Lambda instances discard volatile memory post-invocation, persisting all pipeline state strictly to Amazon S3.
* **Controlled Access Control:** Client-side credentials are not required in the browser. Ingress is managed strictly through API Gateway proxy abstractions.
