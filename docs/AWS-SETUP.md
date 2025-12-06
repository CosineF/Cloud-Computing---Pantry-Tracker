# AWS Setup Guide

## Step 1: Configure AWS Credentials

You need AWS credentials to deploy. You have two options:

### Option A: Using AWS Access Keys (Recommended for CLI)

1. **Get your AWS Access Keys:**
   - Log in to AWS Console: https://console.aws.amazon.com
   - Go to IAM → Users → Your User → Security Credentials
   - Click "Create access key"
   - Choose "Command Line Interface (CLI)"
   - Download or copy the Access Key ID and Secret Access Key

2. **Configure AWS CLI:**
   ```bash
   aws configure
   ```
   
   You'll be prompted for:
   - **AWS Access Key ID**: Paste your access key
   - **AWS Secret Access Key**: Paste your secret key
   - **Default region name**: `ca-central-1` (or your preferred region)
   - **Default output format**: `json` (recommended)

### Option B: Using AWS SSO (If your organization uses it)

```bash
aws configure sso
```

Follow the prompts to set up SSO.

---

## Step 2: Verify Configuration

Check that your credentials are set up:

```bash
aws configure list
aws sts get-caller-identity
```

The second command should return your AWS account ID and user ARN.

---

## Step 3: Deploy Your Application

Once credentials are configured, you can deploy:

```bash
sam build
sam deploy --guided
```

Or if you've already run `sam deploy --guided` and saved the config:

```bash
sam deploy
```

---

## Troubleshooting

### "Unable to locate credentials"
- Make sure you ran `aws configure`
- Check that `~/.aws/credentials` file exists
- Verify your access keys are correct

### "Access Denied" errors
- Check your IAM user has permissions for:
  - CloudFormation
  - Lambda
  - API Gateway
  - DynamoDB
  - IAM (for role creation)

### Region Issues
- Make sure you're deploying to a region where you have access
- Check your default region: `aws configure get region`
- Set a specific region: `aws configure set region ca-central-1`

---

## Security Best Practices

1. **Never commit credentials to git** - They're already in `.gitignore`
2. **Use IAM roles** when possible (for EC2, Lambda, etc.)
3. **Rotate access keys** regularly
4. **Use least privilege** - Only grant permissions needed for deployment

---

## Cost Considerations

The MVP should stay within AWS Free Tier:
- **API Gateway**: 1M requests/month free
- **Lambda**: 1M requests/month + 400K GB-seconds free
- **DynamoDB**: 25GB storage + 25 read/write units free

Estimated cost: **$0-5/month** for typical usage.

---

## Next Steps After Deployment

1. **Get your API Gateway URL** from the deployment output
2. **Update `frontend/app.js`** with the API URL
3. **Test the application** using the frontend
4. **Monitor costs** in AWS Cost Explorer

