# Gemini Pro Quick Start Examples in Python

- Conda 2/3
- Python 3.11

## Environment Setup

```bash
conda create --name google -c conda-forge python=3.11
source activate google
```

Inside `google` conda virtual environment, use `pip3` to install all packages we want,

```bash
pip3 install google-generativeai streamlit python-dotenv

# Optional. Disable stats collection if you want.

cat <<EOT > $HOME/.streamlit/config.toml
[browser]
gatherUsageStats = false
EOT
```

## How to Run

Setup local `.env` file first. We need the following key-value pairs setup. See [Quick Start on Your Google Account and Setup ADC or API Keys](#quick-start-on-your-google-account-and-setup-adc-or-api-keys) to ramp up some default credential settings to use Google Cloud APIs, this is required if you haven't done so.

> Note: for `GOOGLE_API_KEY`, go to  UI <https://console.cloud.google.com/>.

```bash
cat <<EOT > ./.env
GOOGLE_API_KEY="REPLACE_WITH_YOUR_OWN_KEY"
PROJECT_ID="REPLACE_WITH_YOUR_PROJECT_ID"
LOCATION="us-west1"
GOOGLE_APPLICATION_CREDENTIALS="/<WHERE_YOU_STORE_YOUR_GOOGLE_ADC_KEY>/<YOUR_PROJECT_ID_xxxxxx>.json"
EOT
```

```bash
# Gemini Pro Model via generativeai APIs
streamlist run gemini.py

# Gemini 1.5 Pro Model via VertexAI APIs
streamlist run gemini_pro.py
```

## Appendix

### Quick Start on Your Google Account and Setup ADC or API Keys

As first time Google Cloud user, see Google official [doc](https://cloud.google.com/docs/authentication/provide-credentials-adc). For quick and lazy setup, here are the TL;DR version.

> Note: You still need to enable Vertex AI via your Google Console and accept the terms and services, etc.
in your Google account.

simply run the script, it will try to fetch your default project, create an IAM, assign some roles, and
generate the key JSON files for `GOOGLE_APPLICATION_CREDENTIALS`. You can also do it on UI <https://console.cloud.google.com/>.

```bash
./setup_gcloud.sh
```
