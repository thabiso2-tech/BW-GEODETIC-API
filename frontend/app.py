import streamlit as st
import pandas as pd
import requests
import pydeck as pdk # For 3D visualization

st.title("🇧🇼 Botswana National Geodetic Portal")

# File Uploaders
pts_file = st.file_uploader("Upload Approximate Coordinates (CSV)", type=['csv'])
obs_file = st.file_uploader("Upload GNSS Baselines (CSV)", type=['csv'])

if pts_file and obs_file:
    pts_df = pd.read_csv(pts_file)
    obs_df = pd.read_csv(obs_file)

    if st.button("Calculate National Adjustment"):
        payload = {
            "points": pts_df.to_dict(orient='records'),
            "baselines": obs_df.to_dict(orient='records')
        }
        res = requests.post("http://backend:8000/api/v1/adjust", json=payload)
        
        if res.status_code == 200:
            st.success("Network Adjusted Successfully!")
            st.write("Adjusted Values:", res.json()['corrections'])
            
            # Simple 3D Visualization of the Network
            st.pydeck_chart(pdk.Deck(
                layers=[pdk.Layer('ScatterplotLayer', data=pts_df, get_position='[lon, lat]', get_radius=500)]
            ))