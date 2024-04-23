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
GenAI Python Example for Gemini 1.5 Pro via Vertex API
"""

import os
import base64
from dotenv import load_dotenv
import google.generativeai as genai
import vertexai as genvai
import vertexai.generative_models as glm

import streamlit as st

load_dotenv()
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')
PROJECT_ID = os.getenv('PROJECT_ID')
GC_LOCATION = os.getenv('LOCATION', 'us-west1')

genvai.init(project=PROJECT_ID, location=GC_LOCATION)
genai.configure(api_key=GOOGLE_API_KEY)

multimodal_model = glm.GenerativeModel('gemini-1.5-pro-preview-0409')

def generate_content(data_type, promptcmd):
  """func wrapper to process response"""
  match data_type:
    case 'video':
      resp = multimodal_model.generate_content(promptcmd)
      return resp.text
    case _:
      raise SystemExit("Content Type {data_type} not supported! Exiting!")

st.title('Gemini AI Text Generator from Video/Images')
prompt = st.text_input('Enter a prompt OR/AND:')
uploaded_img_file = st.file_uploader("Upload an image", ["jpg","jpeg","png"]) #image uploader
uploaded_video_file = st.file_uploader("Upload a video", ["mp4","mpeg"]) #video uploader

if uploaded_img_file is not None and prompt is not None:
  if st.button('Analyze Image with Prompt'):
    response = generate_content(
      'image',
      [
        glm.Part.from_text(prompt),
        glm.Part.from_image(glm.Image.from_bytes(uploaded_img_file.getvalue()))
      ]
    )
    st.write(response)

if uploaded_video_file is not None and prompt is not None:
  st.video(uploaded_video_file, format="video/mp4", start_time=0)
  if st.button('Analyze Video with Prompt'):
    response = generate_content(
      'video',
      [
        glm.Part.from_text(prompt),
        glm.Part.from_data(
            mime_type='video/mp4',
            data=base64.b64encode(uploaded_video_file.getvalue()).decode()
          )
      ]
    )
    st.write(response)
