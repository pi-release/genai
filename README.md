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

```bash
# Gemini Pro Model via generativeai APIs
streamlist run gemini.py

# Gemini 1.5 Pro Model via VertexAI APIs
streamlist run gemini_pro.py
```
