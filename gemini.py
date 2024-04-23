# Copyright 2024 Blocksync LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""
GenAI Python Example for Gemini Pro
"""

import os
from io import BytesIO
from dotenv import load_dotenv
import google.generativeai as genai
import google.ai.generativelanguage as glm
import streamlit as st

load_dotenv()
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')
genai.configure(api_key=GOOGLE_API_KEY)

model = genai.GenerativeModel('gemini-pro-vision')

for m in genai.list_models():
  if 'generateContent' in m.supported_generation_methods:
    print(m.name)

def generate_content(data_type, promptcmd):
  """func wrapper to process response"""
  match data_type:
    case 'image':
      resp = model.generate_content(promptcmd)
      return resp.text
    case _:
      raise SystemExit("Content Type {data_type} not supported! Exiting!")

st.title('Gemini AI Text Generator')
prompt = st.text_input('Enter a prompt OR/AND:')
uploaded_img_file = st.file_uploader("Upload an image", ["jpg","jpeg","png"]) #image uploader

if uploaded_img_file is not None and prompt is not None:
  st.image(BytesIO(uploaded_img_file.getvalue()), caption="Uploaded Image Displayed Here!")
  if st.button('Analyze Image with Prompt'):
    response = generate_content('image',
      glm.Content(
        parts = [
          glm.Part(text=prompt),
          glm.Part(
            inline_data=glm.Blob(
              mime_type='image/jpeg',
              data=uploaded_img_file.getvalue()
            )
          ),
        ],
      )
    )
    st.write(response)
